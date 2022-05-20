# fix for https://github.com/NixOS/nixpkgs/issues/155664
final: prev: {
	intel-ocl = prev.intel-ocl.overrideAttrs (old: {
		src = final.fetchzip {
			url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/11396/SRB5.0_linux64.zip";
			sha256 = "0qbp63l74s0i80ysh9ya8x7r79xkddbbz4378nms9i7a0kprg9p2";
			stripRoot = false;
		};
	});
}
