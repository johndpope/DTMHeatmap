#!/usr/local/bin/python
import os

def rename_in_dir(d):
    print 'got %s' % (d)
    if d is None:
        return

    for root, dirs, files in os.walk(d):
        print 'in root %s' % (root)
        for filename in files:
            print 'filename is %s' % (filename)
            if "DM" in filename:
                new_filename = filename
                new_filename = new_filename.replace("DM", "DTM")
                print 'moving %s to %s' % (os.path.join(root, filename), os.path.join(root, new_filename))
                # import pdb; pdb.set_trace()
                os.rename(os.path.join(root, filename), os.path.join(root, new_filename))

if __name__ == '__main__':
    rename_in_dir('.')