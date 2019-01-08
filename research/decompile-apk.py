from androguard.misc import AnalyzeAPK
from androguard.core.analysis.analysis import ExternalClass
from pathlib import Path

a, d, dx = AnalyzeAPK("NetHomePlus-ssl-injected.apk")

classes = dx.get_classes()

Path('./source').mkdir(parents=True)

for c in list(classes):
    if "midea/msmartsdk" in c.get_vm_class().get_name():
        if isinstance(c.get_vm_class(), ExternalClass):
            print("[-] {}".format(filePath))
            continue

        path = c.get_vm_class().get_name()[1:-1].split('/')
        className = path[-1]
        path = path[:-1]

        dirStruct = Path('./source/{}'.format('/'.join(path)))
        dirStruct.mkdir(parents=True, exist_ok=True)

        filePath = './source/{}/{}.java'.format(
                '/'.join(path),
                className)
        with open(filePath, 'w') as f:
            f.write(c.get_vm_class().get_source())

        print("[+] {}".format(filePath))

