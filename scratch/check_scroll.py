import json
import re

with open('scratch/widget_tree.json', encoding='utf-8') as f:
    text = f.read()

print('offset:', re.findall(r'offset:[^,"]*', text)[:10])
print('scroll:', re.findall(r'scroll[a-zA-Z0-9_]*:[^,"]*', text)[:10])
print('pixels:', re.findall(r'pixels:[^,"]*', text)[:10])

