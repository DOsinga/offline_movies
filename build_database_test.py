#!/usr/bin/env python

import json
import unittest

import mwparserfromhell

from build_database import strip_nodes, extract_fields_from_template, parse_wiki_text


ARMY_OF_DARKNESS = '''{{Infobox film
 | name = Army of Darkness
 | image = Army of Darkness poster.jpg
 | alt =
 | caption = Theatrical release poster
 | director = [[Sam Raimi]]
 | producer = [[Robert Tapert]]
 | writer = {{Plainlist|
 * Sam Raimi
 * [[Ivan Raimi]]
 }}
 | starring = {{Plainlist|
 * [[Bruce Campbell]]
 * [[Embeth Davidtz]]
 }}
 | music = {{Plainlist|
 * [[Danny Elfman]] {{small|(Themes)}}
 * [[Joseph LoDuca]]
 }}
 | cinematography = [[Bill Pope]]
 | editing = {{Plainlist|
 * [[Bob Murawski]]
 * [[Sam Raimi|R.O.C. Sandstorm]]
 }}
 | production companies = {{Plainlist|
 * [[Dino De Laurentiis|Dino De Laurentiis Communications]]
 * [[Renaissance Pictures]]
 }}
 | distributor = [[Universal Studios|Universal Pictures]]
 | released = {{Film date|1992|10|09|world premiere|1993|02|19|United States}}
 | runtime = 88 minutes < !--Theatrical runtime: 88:46-- > < ref > {{cite web|title=''ARMY OF DARKNESS'' (15)|url=http://www.bbfc.co.uk/releases/army-darkness-1970|work=[[British Board of Film Classification]]|date=1992-12-18|accessdate=2013-03-28}} < /ref >
 | country = United States
 | language = English
 | budget = $11 million < ref name= " the-numbers.com " > http://www.the-numbers.com/movie/Army-of-Darkness#tab=summary < /ref >
 | gross = $21.5 million < ref name= " the-numbers.com " > http://www.the-numbers.com/movie/Army-of-Darkness#tab=summary < /ref >
 }}'''


class TestBuildDataBase(unittest.TestCase):
  def assertEqualWT(self, wiki, stripped):
    wikicode = mwparserfromhell.parse(wiki)
    self.assertEqual(strip_nodes(wikicode.nodes), stripped)

  def test_strip_nodes(self):
    self.assertEqualWT('Hello', 'Hello')
    self.assertEqualWT('Hello [[some where|there]]', 'Hello there')
    self.assertEqualWT('[[Morgan Creek Productions]]<br />[[Franchise Pictures]]<br />Rational Packaging<br />Lansdown Films',
                       'Morgan Creek Productions, Franchise Pictures, Rational Packaging, Lansdown Films')
    self.assertEqualWT('{{ubl|[[Naria Espert]]|[[Rosa Maria Sardez]]|[[Anna Lizaran]]|[[Merces Pons]]}}',
                       'Naria Espert, Rosa Maria Sardez, Anna Lizaran, Merces Pons')
    self.assertEqualWT('{{film date|df=yes|1997|1|17|[[Spain]]}}', 'Jan 17, 1997')
    self.assertEqualWT('{{Film date|1993|02|24|[[Mars]]|2008|03|23}}', 'Feb 24, 1993')
    self.assertEqualWT('{{Plainlist|\n* Sam Raimi\n* [[Ivan Raimi]]}}', 'Sam Raimi, Ivan Raimi')
    self.assertEqualWT('{{Plain list | \n* [[Jeff Bridges]]\n* [[Isabella Rossellini]]\n* [[Rosie Perez]]\n* [[Tom Hulce]]\n* [[John Turturro]]}}',
                       'Jeff Bridges, Isabella Rossellini, Rosie Perez, Tom Hulce, John Turturro')


  def test_extract_fields_from_template(self):
    props = {}
    template = parse_wiki_text(ARMY_OF_DARKNESS).nodes[0]
    extract_fields_from_template(template, props)
    self.assertEqual(props['director'], 'Sam Raimi')
    self.assertEqual(props['running_time'], '88 minutes')
    self.assertEqual(props['written_by'], 'Sam Raimi, Ivan Raimi')

if __name__ == '__main__':
  unittest.main()
