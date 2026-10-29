import xml.etree.ElementTree as ET

tree = ET.parse('scratch/ordering_state.xml')
root = tree.getroot()

node = root
# descend until multiple children
while len(node) == 1:
    node = node[0]

print('Node:', node.attrib)
print('Children count:', len(node))
for i, child in enumerate(node):
    print(f'Child {i}:', child.attrib)

