import urllib.request
import json

url = 'http://127.0.0.1:56426/onGWQ-StwH0=/ext.flutter.inspector.getRootWidgetTree?isolateId=isolates/100531158191043&objectGroup=test'
req = urllib.request.urlopen(url)
res = json.loads(req.read())

def find_node(node, target):
    desc = str(node.get('description', ''))
    if target in desc:
        return node
    for child in node.get('children', []):
        found = find_node(child, target)
        if found:
            return found
    return None

cafe = find_node(res['result']['result'], 'CafeCashierCounterScreen')
scaffold = find_node(cafe, 'Scaffold')
vid = scaffold.get('valueId')
print('Scaffold valueId:', vid)

url_render = 'http://127.0.0.1:56426/onGWQ-StwH0=/ext.flutter.inspector.getSelectedSummaryWidget?isolateId=isolates/100531158191043&id=' + vid + '&objectGroup=test'
try:
    req2 = urllib.request.urlopen(url_render)
    res2 = json.loads(req2.read())
    print('Scaffold summary:', json.dumps(res2, indent=2)[:500])
except Exception as e:
    print('Summary error:', e)
