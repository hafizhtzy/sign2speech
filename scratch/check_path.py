import xml.etree.ElementTree as ET

tree = ET.parse('scratch/ordering_state.xml')
root = tree.getroot()

def find_path(node, path=[]):
    desc = node.attrib.get('content-desc', '')
    bounds = node.attrib.get('bounds', '')
    cls = node.attrib.get('class', '')
    new_path = path + [f'{cls} {bounds} {desc}']
    if 'Lanjut: Nama & Bayar' in desc:
        print('PATH TO BUTTON:')
        for step in new_path:
            print('  ->', step)
        return True
    for child in node:
        if find_path(child, new_path):
            return True
    return False

find_path(root)

