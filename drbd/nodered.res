resource nodered {
  disk {
	  fencing resource-and-stonith;
  }
  handlers {
	  fence-peer		"/usr/lib/drbd/crm-fence-peer.sh";
	  after-resync-target	"/usr/lib/drbd/crm-unfence-peer.sh";
  }
  net {
    allow-two-primaries;
    after-sb-0pri discard-zero-changes;
    after-sb-1pri discard-secondary;
    after-sb-2pri disconnect;
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