import json

with open('scratch/widget_tree.json', encoding='utf-8') as f:
    tree = json.load(f)

res = tree['result']['result']

def find_node(node, target):
    desc = str(node.get('description', ''))
    if target in desc:
        return node
    for child in node.get('children', []):
        found = find_node(child, target)
        if found:
            return found
    return None

cafe_screen = find_node(res, 'CafeCashierCounterScreen')
rb = find_node(cafe_screen, 'RotatedBox')
print('RotatedBox node full dict:')
print(json.dumps(rb, indent=2)[:500])

