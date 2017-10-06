# Gathering statistics about memory leaks

These tools can be run against different Gluster versions and will account
memory leaks for short living processes (currently `qemu-img`). The aim is to
reduce the memory leaks in Gluster when applications use `libgfapi` to access
the storage.
