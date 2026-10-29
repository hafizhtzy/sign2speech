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

def find_all(node, target, results):
    desc = str(node.get('description', ''))
    if target in desc:
        results.append(node)
    for child in node.get('children', []):
        find_all(child, target, results)

cards = []
find_all(cafe_screen, 'CafeCashierSignVideoCard', cards)
print(f'Found {len(cards)} CafeCashierSignVideoCard')
if cards:
    c = cards[0]
    print('Description:', c.get('description'))
    print('Children count:', len(c.get('children', [])))
    for child in c.get('children', []):
        print('  child:', child.get('description'))

decks = []
find_all(cafe_screen, 'CashierOrderDeckCard', decks)
print(f'Found {len(decks)} CashierOrderDeckCard')
if decks:
    d = decks[0]
    print('Description:', d.get('description'))
    print('Children count:', len(d.get('children', [])))
    for child in d.get('children', []):
        print('  child:', child.get('description'))

