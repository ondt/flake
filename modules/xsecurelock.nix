{ inputs, options, config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.services.xsecurelock; in {
	options.services.xsecurelock = {
		enable = mkEnableOption "xsecurelock";
		# TODO: add more options (`xsecurelock --help`)
		showDatetime = mkOption {
			default = false;
			example = true;
			type = types.bool;
			description = "Whether to show local date and time on the login.";
		};
		datetimeFormat = mkOption {
			default = "%c";
			example = "%a %d %b %Y %T %Z";
			type = types.str;
			description = "The date format to show. Defaults to the locale settings. See `man date` for possible formats.";
		};
		authTimeout = mkOption {
			default = 5 * 60;
			example = 120;
			type = types.int;
			description = "Specifies the time (in seconds) to wait for response to a prompt by auth_x11 before giving up and reverting to the screen saver.";
		};
		dimTimeMs = mkOption {
			default = 2000;
			type = types.int;
			description = "Milliseconds to dim for when above xss-lock command line with dimmer is used.";
		};
		waitTimeMs = mkOption {
			default = 5000;
			example = 10000;
			type = types.int;
			description = "Milliseconds to wait after dimming (and before locking) when above xss-lock command line is used. Should be at least as large as the period time set using `xset s`.";
		};
		discardFirstKeypress = mkOption {
			default = true;
			type = types.bool;
			description = "If set to false, the key pressed to stop the screen saver and spawn the auth child is sent to the auth child (and thus becomes part of the password entry). By default we always discard the key press that started the authentication flow, to prevent users from getting used to type their password on a blank screen (which could be just powered off and have a chat client behind or similar).";
		};
		keybindings = mkOption {
			default = {};
			example = { XF86AudioPlay = "echo example"; };
			type = types.attrsOf types.str;
			description = "A shell command to execute when the specified key (keysym) is pressed. Useful e.g. for media player control. Beware: be cautious about what you run with this, as it may yield attackers control over your computer.";
		};
	};

	config = mkIf cfg.enable {
		programs.xss-lock = {
			enable = true;
			lockerCommand = "${pkgs.xsecurelock}/bin/xsecurelock";
			extraOptions = [
				"--transfer-sleep-lock"
				"--notifier=${pkgs.xsecurelock}/libexec/xsecurelock/dimmer"
			];
		};

		systemd.user.services.xss-lock.environment = {
			XSECURELOCK_SHOW_DATETIME = if cfg.showDatetime then "1" else "0";
			XSECURELOCK_DATETIME_FORMAT = builtins.replaceStrings ["%"] ["%%"] cfg.datetimeFormat;
			XSECURELOCK_AUTH_TIMEOUT = toString cfg.authTimeout;
			XSECURELOCK_DIM_TIME_MS = toString cfg.dimTimeMs;
			XSECURELOCK_WAIT_TIME_MS = toString cfg.waitTimeMs;
			XSECURELOCK_DISCARD_FIRST_KEYPRESS = if cfg.discardFirstKeypress then "1" else "0";
		} // lib.mapAttrs' (name: value: lib.nameValuePair "XSECURELOCK_KEY_${name}_COMMAND" value) cfg.keybindings;
	};
}
