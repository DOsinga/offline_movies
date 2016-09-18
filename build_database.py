#!/usr/bin/env python
import os
import re
from PIL import Image
from io import BytesIO
from hashlib import md5
import argparse
import psycopg2
import psycopg2.extras
import sqlite3
import datetime
import mwparserfromhell
import requests

from mwparserfromhell.nodes.text import Text
from mwparserfromhell.nodes.wikilink import Wikilink
from mwparserfromhell.nodes.tag import Tag
from mwparserfromhell.nodes.template import Template

FIELD_MAP = {'name': 'title',
             'director': 'director',
             'writer': 'written_by',
             'screenplay': 'written_by',
             'starring': 'starring',
             'image': 'image',
             'runtime': 'running_time',
             'released': 'release_date',
             'reception': 'reception',
             'language': 'language'}
FIELD_MAP_KEYS = sorted(FIELD_MAP.values())
RECEPTION_TITLES = {'reception', 'responses and reception', 'critical reception', 'box office and reception',
                    'release and reception', 'production, distribution, and reception', 'critical reaction',
                    'critical response', 'reaction and legacy', 'legacy', 'response'}
IMAGE_PATH_EN = 'http://upload.wikimedia.org/wikipedia/en/%s/%s/%s'
IMAGE_PATH_COMMONS = 'http://upload.wikimedia.org/wikipedia/commons/%s/%s/%s'

MULTILINE_BREAKS = re.compile('\n\n+')

def setup_db(path):
  if os.path.isfile(path):
    os.remove(path)
  conn = sqlite3.connect(path)
  cursor = conn.cursor()
  cursor.execute('CREATE TABLE movie ( '
                 '   title TEXT,'
                 '   director TEXT,'
                 '   written_by TEXT,'
                 '   starring TEXT,'
                 '   running_time TEXT,'
                 '   release_date TEXT,'
                 '   language TEXT,'
                 '   reception TEXT,'
                 '   image BLOB'
                 ')')

  cursor.execute("CREATE VIRTUAL TABLE movie_text USING fts4 (content='movie', title, starring)")
  return conn, cursor

def strip_node(node):
  if isinstance(node, Text):
    return node.value
  elif isinstance(node, Wikilink):
    return strip_nodes((node.text or node.title).nodes)
  elif isinstance(node, Tag):
    if node.tag == 'br':
      return ', '
  elif isinstance(node, Template):
    template_name = node.name.lower().strip().replace(' ', '')
    if template_name == 'ubl':
      value = [strip_nodes(param.value.nodes) for param in node.params if param.name.isdigit()]
      return ', '.join(value)
    elif template_name == 'plainlist':
      if not node.params:
        return ''
      res = []
      for v in strip_nodes(node.params[0].value.nodes).split('\n'):
        v = v.strip()
        if v.startswith('*'):
          v = v[1:]
        v = v.strip()
        if v:
          res.append(v)
      return ', '.join(res)
    elif template_name == 'filmdate':
      date = [strip_nodes(param.value.nodes) for param in node.params if param.name.isdigit() if param.strip()][:3]
      if len(date) == 1:
        return str(date[0])
      elif len(date) != 3:
        return ''
      try:
        date = map(lambda x: int(x or 1), date)
      except ValueError:
        return ''
      if node.has('df') and node.get('df').startswith('y'):
        year, day, month = date
      else:
        year, month, day = date
      try:
        date = datetime.datetime(year, month, day)
        return date.strftime('%b %d, %Y')
      except ValueError:
        return ''
  return ''

def strip_nodes(nodes):
  """There is a node.strip_code() but that only returns text. We want to do a little better."""
  return ''.join(strip_node(x) for x in nodes)

def parse_wiki_text(wikitext):
  return mwparserfromhell.parse(wikitext)

def fetch_image(image_name, image_cache):
  if not image_name or image_name.endswith('.tiff'):
    return None
  image_name = image_name.replace(' ', '_')
  if image_name[0].upper() != image_name[0]:
    image_name = image_name.capitalize()
  file_path = os.path.join(image_cache, image_name)
  if os.path.isfile(file_path):
    image = Image.open(file(file_path))
  else:
    m = md5()
    m.update(image_name.encode('utf-8'))
    c = m.hexdigest()
    path = IMAGE_PATH_EN % (c[0], c[0:2], image_name)
    r = requests.get(path)
    if r.status_code == 404:
      path = IMAGE_PATH_COMMONS % (c[0], c[0:2], image_name)
      r = requests.get(path)
      if r.status_code == 404:
        print image_name
        return None
    try:
      image = Image.open(BytesIO(r.content))
    except IOError:
      return None
    image.save(file(file_path, 'w'))
  image.thumbnail((240, 640), Image.ANTIALIAS)
  res = BytesIO()
  if image.mode == 'P':
    image = image.convert('RGB')
  try:
    image.save(res, 'WEBP', quality=15)
  except IOError as err:
    print image_name, err.message
    return None
  return sqlite3.Binary(res.getvalue())

def extract_reception_text(wikitext):
  section = []
  section_level = None
  in_reception = False
  for line in wikitext.split('\n'):
    title = line.strip('=')
    level = (len(line) - len(title)) - 1
    if level > 0:
      title = parse_wiki_text(title).strip_code().strip().lower()
      if title in RECEPTION_TITLES:
        in_reception = True
        section_level = level
      elif in_reception and level <= section_level:
        in_reception = False
    elif in_reception:
      section.append(line)
  if section:
    res = parse_wiki_text('\n'.join(section)).strip_code()
    return MULTILINE_BREAKS.sub('\n', res)
  else:
    return None


def extract_fields_from_template(template, to_insert):
  for param in template.params:
    key = param.name.strip()
    field_name = FIELD_MAP.get(key)
    if field_name:
      value = strip_nodes(param.value.nodes)
      # Sometimes comments are written as < -
      p = value.find('<')
      if p != -1:
        value = value[:p]
      to_insert[field_name] = value.strip()

def main(postgres_cursor, sqlite_cursor, image_cache):
  # Get the 12000 most popular movies:
  print 'Getting top movies...'
  postgres_cursor.execute(
    "SELECT wikipedia.*, wikistats.viewcount FROM wikipedia "
    "JOIN wikistats ON wikipedia.title = wikistats.title WHERE wikipedia.infobox = 'film' "
    "ORDER BY wikistats.viewcount DESC limit 15000"
  )
#  postgres_cursor.execute("SELECT * FROM wikipedia WHERE infobox = 'film' limit 12000")
  print 'Done'
  count = 0
  no_reception = 0
  image_count = 0
  for film in postgres_cursor:
    count += 1
    if count % 100 == 0:
      print count, no_reception, image_count
    to_insert = {field: '' for field in FIELD_MAP.values()}
    to_insert['reception'] = extract_reception_text(film['wikitext'])
    if not to_insert['reception']:
      no_reception += 1
      continue
    wikicode = parse_wiki_text(film['wikitext'])
    for template in wikicode.filter_templates():
      if template.name.lower().startswith('infobox '):
        extract_fields_from_template(template, to_insert)
        break
    else:
      continue
    to_insert['image'] = fetch_image(to_insert['image'], image_cache)
    if to_insert['image']:
      image_count += 1

    if not to_insert.get('title'):
      to_insert['title'] = film['title'].decode('utf8')

    sql = 'INSERT INTO movie (%s) VALUES (%s)' % (', '.join(FIELD_MAP_KEYS), ', '.join('?' for _ in FIELD_MAP_KEYS))
    try:
      sqlite_cursor.execute(sql, [to_insert.get(fn) for fn in FIELD_MAP_KEYS])
    except sqlite3.ProgrammingError as err:
      print 'Error:', err.message
      print `to_insert`
    # Rebuild the full text search index:
    sqlite_cursor.execute("INSERT INTO movie_text(movie_text) VALUES('rebuild')")


if __name__ == '__main__':
  parser = argparse.ArgumentParser(description='Fetch movies from a previously processed wikipedia dump out of postgres')
  parser.add_argument('--postgres', type=str,
                      help='postgres connection string')
  parser.add_argument('--image_cache', type=str,
                      default='image_cache',
                      help='postgres connection string')
  parser.add_argument('sqlite_db', type=str,
                      help='Sqlite db for use in the app')

  args = parser.parse_args()

  postgres_conn = psycopg2.connect(args.postgres)
  postgres_cursor = postgres_conn.cursor(cursor_factory=psycopg2.extras.DictCursor)

  sqlite_conn, sqlite_cursor = setup_db(args.sqlite_db)

  if not os.path.isdir(args.image_cache):
    os.makedirs(args.image_cache)
  main(postgres_cursor, sqlite_cursor, args.image_cache)

  sqlite_conn.commit()
  sqlite_cursor.close()
  sqlite_conn.close()




