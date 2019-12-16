#!/usr/bin/env python3
from bs4 import BeautifulSoup, Comment
import os, os.path

for root, dirs, files in os.walk('static/performance'):
    for file in files:
        if file.endswith('.html'):
            try:
                fname = os.path.join(root, file)
                print(f'Doing {fname}')
                with open(fname) as f:
                    soup = BeautifulSoup(f.read(), features="lxml")

                for script in soup.find_all('script'):
                    script.extract()

                for comment in soup.find_all(string=lambda text: isinstance(text, Comment)): # comments can contain stuff like "[if lt IE 9]><script"
                    comment.extract()

                for child in soup.recursiveChildGenerator():
                    if 'attrs' in dir(child):
                        for key in list(child.attrs.keys()):
                            if key.startswith('on'):
                                print(f'Failed on {fname}, attribute: {key}')
                                assert False

                for anchor in soup.find_all('a'):
                    href = anchor.attrs['href']
                    if len(href) and href[0] not in ['/', '?', '#'] and not href.startswith('https:') and not href.startswith('http:') and not href.startswith('mailto:') and href not in ['not published yet', 'tax-disc', 'sorn']:
                        print(f'Failed on {fname}, href: {href}')
                        assert False

                with open(fname, 'w') as f:
                    f.write(soup.prettify())
            except Exception as e:
                print(e)
