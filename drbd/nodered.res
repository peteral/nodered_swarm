resource nodered {
 handlers {
    before-resync-target "/usr/lib/drbd/snapshot-resync-target-lvm.sh";
    after-resync-target "/usr/lib/drbd/unsnapshot-resync-target-lvm.sh";
  }
  volume 0 {
    device    /dev/drbd1;
    disk      /dev/gigby-v01-vg/nodered;
    meta-disk internal;
  }
  on gigby-v01 {
    address   192.168.210.1:7789;
  }
  on gigby-v02 {
    address   192.168.210.2:7789;
  }
}