/*
 * Main.vala
 *
 * Copyright 2017 Tony George <teejeetech@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */

using GLib;
using Gtk;
using Gee;
using Json;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JsonHelper;
using TeeJee.ProcessHelper;
using TeeJee.GtkHelper;
using TeeJee.System;
using TeeJee.Misc;

public Main App;
public const string AppName = "Polo File Manager";
public const string AppShortName = "polo";
public const string AppVersion = "17.5.1 (BETA 6)";
public const string AppAuthor = "Tony George";
public const string AppAuthorEmail = "teejeetech@gmail.com";

const string GETTEXT_PACKAGE = "";
const string LOCALE_DIR = "/usr/share/locale";

extern void exit(int exit_code);

public class Main : GLib.Object {

	public string[] cmd_args;
	public bool gui_mode = false;
	
	public string user_name = "";
	public string user_name_effective = "";
	public string user_home = "";
	public string user_home_effective = "";
	public int user_id = -1;
	public int user_id_effective = -1;
	public XdgUserDirectories user_dirs = null;
	
	public bool add_context_menu = true;
	public bool add_context_submenu = false;
	public bool associate_archives = true;
	public string last_input_dir = "";
	public string last_output_dir = "";

	public bool first_run = false;
	public FileItem fs_root = null;

	public AppLock session_lock;

	public Gee.HashMap<string,Tool> Tools = new Gee.HashMap<string,Tool>();

	public string temp_dir = "";
	public string current_dir = "";
	public string share_dir = "/usr/share";
	public string app_conf_path = "";
	public string app_conf_folders = "";
	public string app_conf_session = "";
	public string app_conf_archive = "";
	public string app_conf_dir_path = "";
	public string app_conf_dir_path_open = "";
	
	//public ArchiveTask archive_task;
	//public DesktopApp crunchy_app;
	//public Gee.ArrayList<MimeType> mimetype_list;
	public Json.Object default_config;
	public Bash bash_admin_shell;

	public AppMode app_mode = AppMode.OPEN;
	public Gee.ArrayList<string> cmd_files;
	public string arg_outpath = "";
	public bool arg_same_path = false;
	public bool arg_prompt_outpath = false;

	public bool use_large_icons_nav_pane = false;
	public ViewMode view_mode = ViewMode.ICONS;
	public bool single_click_activate = false;
	public bool restore_last_session = true;

	public bool sidebar_visible = true;
	public bool sidebar_bookmarks = true;
	public bool sidebar_places = true;
	public bool sidebar_devices = true;
	public bool sidebar_dark = false;
	public bool sidebar_unmount = false;
	public bool sidebar_lock = false;
	public int sidebar_position = 150;
	public string sidebar_collapsed_sections = "";

	public bool headerbar_enabled = false;
	public bool headerbar_enabled_temp = false;

	public bool middlebar_visible = true;

	public bool toolbar_visible = true;
	public bool toolbar_large_icons = false;
	public bool toolbar_dark = false;
	public bool toolbar_labels = true;
	public bool toolbar_labels_beside_icons = true;

	public bool toolbar_item_back = true;
	public bool toolbar_item_next = true;
	public bool toolbar_item_up = true;
	public bool toolbar_item_reload = true;
	public bool toolbar_item_home = true;
	public bool toolbar_item_terminal = true;
	public bool toolbar_item_hidden = true;
	public bool toolbar_item_dual_pane = true;
	public bool toolbar_item_view = true;
	public bool toolbar_item_bookmarks = true;
	public bool toolbar_item_devices = true;

	public bool pathbar_unified = false;
	public bool pathbar_use_buttons = false;
	public bool pathbar_flat_buttons = false;
	public bool pathbar_show_bookmarks = true;
	public bool pathbar_show_disks = true;
	public bool pathbar_show_back = false;
	public bool pathbar_show_next = false;
	public bool pathbar_show_up = false;
	public bool pathbar_show_swap = true;
	public bool pathbar_show_other = true;
	public bool pathbar_show_close = true;

	public bool statusbar_unified = false;

	public bool confirm_delete = true;
	public bool confirm_trash = true;

	public bool tabs_bottom = false;
	public bool tabs_close_visible = true;

	public static string REQUIRED_COLUMNS = "name,indicator,spacer";
	public static string REQUIRED_COLUMNS_END = "spacer";
	public static string DEFAULT_COLUMNS = "name,indicator,size,modified,filetype,spacer";
	public static string DEFAULT_COLUMN_ORDER = "name,indicator,size,modified,filetype,permissions,user,group,access,mimetype,symlink_target,original_path,deletion_date,compressed,md5,spacer";
	public string selected_columns = DEFAULT_COLUMNS;

	public bool show_hidden_files = false;
	public PanelLayout panel_layout = PanelLayout.SINGLE;
	public bool maximise_on_startup = true;
	public bool single_instance_mode = true;
	
	// defaults
	public static double LV_FONT_SCALE = 1.0;
	public static int LV_ICON_SIZE = 16;
	public static int LV_ROW_SPACING = 0;

	public static int IV_ICON_SIZE = 64;
	public static int IV_ROW_SPACING = 10;
	public static int IV_COLUMN_SPACING = 50;

	public static int TV_ICON_SIZE = 80;
	public static int TV_ROW_SPACING = 2;
	public static int TV_PADDING = 2;

	public static int SESSION_FORMAT_VERSION = 1;
	public static int APP_CONFIG_FORMAT_VERSION = 1;
	public static int APP_CONFIG_FOLDERS_FORMAT_VERSION = 1;
	public static int APP_CONFIG_ARCHIVE_FORMAT_VERSION = 1;

	public double listview_font_scale = LV_FONT_SCALE;
	public int listview_icon_size = LV_ICON_SIZE;
	public int listview_row_spacing = LV_ROW_SPACING;
	public bool listview_emblems = false;
	public bool listview_thumbs = false;
	public bool listview_transparency = true;

	public int iconview_icon_size = IV_ICON_SIZE;
	public int iconview_row_spacing = IV_ROW_SPACING;
	public int iconview_column_spacing = IV_COLUMN_SPACING;
	public bool iconview_emblems = true;
	public bool iconview_thumbs = true;
	public bool iconview_transparency = true;

	public int tileview_icon_size = TV_ICON_SIZE;
	public int tileview_row_spacing = TV_ROW_SPACING;
	public int tileview_padding = TV_PADDING;
	public bool tileview_emblems = true;
	public bool tileview_thumbs = true;
	public bool tileview_transparency = true;

	public Gee.ArrayList<string> mediaview_exclude = new Gee.ArrayList<string>();
	public Gee.ArrayList<string> mediaview_include = new Gee.ArrayList<string>();

	public string status_line = "";
	public int64 progress_count;
	public int64 progress_total;

	public MainWindow main_window = null;

	public TrashCan trashcan;

	public string admin_pass = "";

	public string[] supported_formats_open;

	public static string[] extensions_tar = {
		".tar"
	};

	public static string[] extensions_tar_compressed = {
		".tar.gz", ".tgz",
		".tar.bzip2",".tar.bz2", ".tbz", ".tbz2", ".tb2",
		".tar.lzma", ".tar.lz", ".tlz",
		".tar.lzo",
		".tar.xz", ".txz"
	};

	public static string[] extensions_tar_packed = {
		".tar.7z",
		".tar.zip",
		".deb"
	};

	public static string[] extensions_7z_unpack = {
		".001", ".7z" , ".lzma",
		".bz2", ".bzip2",
		".gz" , ".gzip",
		".zip", ".jar", ".war", ".ear",
		".rar", ".cab", ".arj", ".z", ".taz", ".cpio",
		".rpm", ".deb",
		".lzh", ".lha",
		".chm", ".chw", ".hxs",
		".iso", ".dmg", ".dar", ".xar", ".hfs", ".ntfs", ".fat", ".vhd", ".mbr",
		".wim", ".swm", ".squashfs", ".cramfs", ".scap"
	};

	public static string[] extensions_single_file = {
		".bz2", ".gz", ".xz", ".lzo"
	};

	public static string[] formats_single_file = {
		"bz2", "gz", "xz", "lzo"
	}; //7z,zip,tar support multiple files

	public Main(string[] args, bool _gui_mode) {

		App = this;

		cmd_args = args;

		gui_mode = _gui_mode;

		cmd_files = new Gee.ArrayList<string>();

		//get user info
		
		user_name = get_username();
		user_name_effective = get_username_effective();
		user_id = get_user_id();
		user_id_effective = get_user_id_effective();
		user_home = get_user_home();
		user_home_effective = get_user_home_effective();

		user_dirs = new XdgUserDirectories(user_name);

		SystemUser.query_users();
		SystemGroup.query_groups();

		session_lock = new AppLock();
		session_lock.create(AppShortName, "session"); // may succeed or fail
		
		Device.init();

		FileItem.init();
		IconManager.init(args, AppShortName);
		Thumbnailer.init();

		IconCache.enable();

		app_conf_dir_path = path_combine(user_home, ".config/polo");
		app_conf_dir_path_open = path_combine(app_conf_dir_path, "open");

		app_conf_path     = path_combine(app_conf_dir_path, "polo.json");
		app_conf_folders  = path_combine(app_conf_dir_path, "polo-folders.json");
		app_conf_session  = path_combine(app_conf_dir_path, "polo-last-session.json");
		app_conf_archive = path_combine(app_conf_dir_path, "polo-archive.json");

		dir_create(app_conf_dir_path);
		dir_create(app_conf_dir_path_open);
		
		// create default objects
		//archive = new ArchiveFile();
		//archive_task = new ArchiveTask();
		//ArchiveCache.refresh();

		supported_formats_open = {
			".tar",
			".tar.gz", ".tgz",
			".tar.bzip2", ".tar.bz2", ".tbz", ".tbz2", ".tb2",
			".tar.lzma", ".tar.lz", ".tlz",
			".tar.xz", ".txz",
			".tar.7z",
			".tar.zip",
			".7z", ".lzma",
			".bz2", ".bzip2",
			".gz", ".gzip",
			".zip", ".rar", ".cab", ".arj", ".z", ".taz", ".cpio",
			".rpm", ".deb",
			".lzh", ".lha",
			".chm", ".chw", ".hxs",
			".iso", ".dmg", ".xar", ".hfs", ".ntfs", ".fat", ".vhd", ".mbr",
			".wim", ".swm", ".squashfs", ".cramfs", ".scap"
		};

		//initialize current_dir as current directory for CLI mode
		if (!gui_mode) {
			current_dir = Environment.get_current_dir();
		}

		try {
			//create temp dir
			temp_dir = get_temp_file_path();

			var f = File.new_for_path(temp_dir);
			if (f.query_exists()) {
				Posix.system("rm -rf %s".printf(temp_dir));
			}
			f.make_directory_with_parents();
		}
		catch (Error e) {
			log_error (e.message);
		}

		MimeType.query_mimetypes();
		DesktopApp.query_apps();
		MimeApp.query_mimeapps(user_home);

		trashcan = new TrashCan(user_id_effective, user_name_effective, user_home_effective);
		trashcan.query_items(false);

		/*foreach(var app in DesktopApp.applist.values){
			if (app.desktop_file_name == "crunchy.desktop"){
				crunchy_app = app;
				break;
			}
		}*/

		fs_root = new FileItem.from_path_and_type("/", FileType.DIRECTORY, true);

		//load_mimetype_list();

		init_tools_list();

		load_app_config();
	}

	public void start_bash_admin_shell(){
		if (bash_admin_shell == null){
			bash_admin_shell = new Bash();
			bash_admin_shell.start_shell();
			//Device.bash_admin_shell = bash_admin_shell;
		}
	}

/*
	private void load_mimetype_list(){

		var mime_list = new Gee.ArrayList<string>();
		string mimelist = "/usr/share/%s/mimetypes".printf(AppShortName);
		if (file_exists(mimelist)){
			foreach(string line in file_read(mimelist).split("\n")){
				mime_list.add(line.strip());
			}
		}

		var list = new Gee.ArrayList<MimeType>();
		foreach(string key in MimeType.mimetypes.keys) {
			if (mime_list.contains(key)){
				var mime = MimeType.mimetypes[key];
				//mime.is_selected = true; // let user select explicitly
				list.add(mime);
			}
		}

		list.sort((a, b) => {
			return strcmp(a.comment,b.comment);
		});

		mimetype_list = list;
	}
*/

	public bool check_dependencies(out string msg) {
		msg = "";

		string[] dependencies = { "grep", "find", "xdg-mime" }; //"7z", "tar", "gzip",

		foreach(string cmd_tool in dependencies) {
			if (!command_exists(cmd_tool)) {
				msg += " * " + cmd_tool + "\n";
			}
		}

		if (msg.length > 0) {
			msg = _("Commands listed below are not available on this system") + ":\n\n" + msg + "\n";
			msg += _("Please install required packages and try running again");
			log_msg(msg);
			return false;
		}
		else {
			return true;
		}
	}

	public void init_tools_list(){
		
		//Encoders["avconv"] = new Encoder("avconv","Libav Encoder","Audio-Video Decoding");
		Tools["ffmpeg"] = new Tool("ffmpeg","FFmpeg Encoder","Generate thumbnails for video");
		Tools["mediainfo"] = new Tool("mediainfo","MediaInfo","Read media properties from audio and video files");
		Tools["exiftool"] = new Tool("exiftool","ExifTool","Read EXIF properties from JPG/TIFF/PNG/PDF files");
		Tools["tar"] = new Tool("tar","tar","Read and extract TAR archives");
		Tools["7z"] = new Tool("7z","7zip","Read and extract multiple archive formats");
		Tools["lzop"] = new Tool("lzop","lzop","Read and extract LZO archives");
		Tools["pv"] = new Tool("pv","pv","Get progress info for compression and extraction");
		Tools["lsblk"] = new Tool("lsblk","lsblk","Read device information");
		Tools["udisksctl"] = new Tool("udisksctl","udisksctl","Mount and unmount devices");
		Tools["cryptsetup"] = new Tool("cryptsetup","cryptsetup","Unlock encrypted LUKS devices");
		Tools["xdg-mime"] = new Tool("xdg-mime","xdg-mime","Set file type associations");
		
		check_all_tools();
		
		//Encoders["ffplay"] = new Encoder("ffplay","FFmpeg's Audio Video Player","Audio-Video Playback");
		//Encoders["avplay"] = new Encoder("avplay","Libav's Audio Video Player","Audio-Video Playback");
		//Encoders["mplayer"] = new Encoder("mplayer","Media Player","Audio-Video Playback");
		//Encoders["mplayer2"] = new Encoder("mplayer2","Media Player","Audio-Video Playback");
		//Encoders["mpv"] = new Encoder("mpv","Media Player","Audio-Video Playback");
		//Encoders["smplayer"] = new Encoder("smplayer","Media Player","Audio-Video Playback");
		//Encoders["vlc"] = new Encoder("vlc","Media Player","Audio-Video Playback");
	}

	public void check_all_tools(){
		foreach(var tool in Tools.values){
			tool.check_availablity();
		}
	}
	
	/* Common */

	public string create_log_dir() {
		string log_dir = "%s/.local/logs/%s".printf(user_home, AppShortName);
		dir_create(log_dir);
		return log_dir;
	}

	public void save_app_config() {

		var config = new Json.Object();

		//if (archive_task != null){
		//	config = archive_task.to_json();
		//}

		set_numeric_locale("C"); // switch numeric locale

		//config.set_string_member("first_run", first_run.to_string());

		config.set_int_member("format-version", (int64) APP_CONFIG_FORMAT_VERSION);

		config.set_string_member("middlebar_visible", middlebar_visible.to_string());
		config.set_string_member("sidebar_visible", sidebar_visible.to_string());
		config.set_string_member("sidebar_dark", sidebar_dark.to_string());
		config.set_string_member("sidebar_places", sidebar_places.to_string());
		config.set_string_member("sidebar_bookmarks", sidebar_bookmarks.to_string());
		config.set_string_member("sidebar_devices", sidebar_devices.to_string());
		config.set_string_member("sidebar_position", sidebar_position.to_string());
		config.set_string_member("sidebar_unmount", sidebar_unmount.to_string());
		config.set_string_member("sidebar_lock", sidebar_lock.to_string());
		config.set_string_member("sidebar_collapsed_sections", sidebar_collapsed_sections);
		
		//save headerbar_enabled_temp instead of headerbar_enabled
		config.set_string_member("headerbar_enabled", headerbar_enabled_temp.to_string());

		config.set_string_member("show_hidden_files", show_hidden_files.to_string());
		config.set_string_member("panel_layout", ((int)panel_layout).to_string());
		config.set_string_member("view_mode", ((int)view_mode).to_string());

		config.set_string_member("listview_font_scale", listview_font_scale.to_string());
		config.set_string_member("listview_icon_size", listview_icon_size.to_string());
		config.set_string_member("listview_row_spacing", listview_row_spacing.to_string());
		config.set_string_member("listview_emblems", listview_emblems.to_string());
		config.set_string_member("listview_thumbs", listview_thumbs.to_string());
		config.set_string_member("listview_transparency", listview_transparency.to_string());

		config.set_string_member("iconview_icon_size", iconview_icon_size.to_string());
		config.set_string_member("iconview_row_spacing", iconview_row_spacing.to_string());
		config.set_string_member("iconview_column_spacing", iconview_column_spacing.to_string());
		config.set_string_member("iconview_emblems", iconview_emblems.to_string());
		config.set_string_member("iconview_thumbs", iconview_thumbs.to_string());
		config.set_string_member("iconview_transparency", iconview_transparency.to_string());

		config.set_string_member("tileview_icon_size", tileview_icon_size.to_string());
		config.set_string_member("tileview_row_spacing", tileview_row_spacing.to_string());
		config.set_string_member("tileview_padding", tileview_padding.to_string());
		config.set_string_member("tileview_emblems", tileview_emblems.to_string());
		config.set_string_member("tileview_thumbs", tileview_thumbs.to_string());
		config.set_string_member("tileview_transparency", tileview_transparency.to_string());

		config.set_string_member("toolbar_visible", toolbar_visible.to_string());
		config.set_string_member("toolbar_large_icons", toolbar_large_icons.to_string());
		config.set_string_member("toolbar_dark", toolbar_dark.to_string());
		//config.set_string_member("toolbar_unified", toolbar_unified.to_string());
		config.set_string_member("toolbar_labels", toolbar_labels.to_string());
		config.set_string_member("toolbar_labels_beside_icons", toolbar_labels_beside_icons.to_string());

		config.set_string_member("toolbar_item_back", toolbar_item_back.to_string());
		config.set_string_member("toolbar_item_next", toolbar_item_next.to_string());
		config.set_string_member("toolbar_item_up", toolbar_item_up.to_string());
		config.set_string_member("toolbar_item_reload", toolbar_item_reload.to_string());
		config.set_string_member("toolbar_item_home", toolbar_item_home.to_string());
		config.set_string_member("toolbar_item_terminal", toolbar_item_terminal.to_string());
		config.set_string_member("toolbar_item_hidden", toolbar_item_hidden.to_string());
		config.set_string_member("toolbar_item_dual_pane", toolbar_item_dual_pane.to_string());
		config.set_string_member("toolbar_item_view", toolbar_item_view.to_string());
		config.set_string_member("toolbar_item_bookmarks", toolbar_item_bookmarks.to_string());
		config.set_string_member("toolbar_item_devices", toolbar_item_devices.to_string());

		config.set_string_member("pathbar_unified", pathbar_unified.to_string());
		config.set_string_member("pathbar_use_buttons", pathbar_use_buttons.to_string());
		config.set_string_member("pathbar_flat_buttons", pathbar_flat_buttons.to_string());

		config.set_string_member("pathbar_show_bookmarks", pathbar_show_bookmarks.to_string());
		config.set_string_member("pathbar_show_disks", pathbar_show_disks.to_string());
		config.set_string_member("pathbar_show_back", pathbar_show_back.to_string());
		config.set_string_member("pathbar_show_next", pathbar_show_next.to_string());
		config.set_string_member("pathbar_show_up", pathbar_show_up.to_string());
		config.set_string_member("pathbar_show_swap", pathbar_show_swap.to_string());
		config.set_string_member("pathbar_show_other", pathbar_show_other.to_string());
		config.set_string_member("pathbar_show_close", pathbar_show_close.to_string());

		config.set_string_member("statusbar_unified", statusbar_unified.to_string());

		config.set_string_member("tabs_bottom", tabs_bottom.to_string());
		config.set_string_member("tabs_close_visible", tabs_close_visible.to_string());

		config.set_string_member("selected_columns", selected_columns);
		config.set_string_member("maximise_on_startup", maximise_on_startup.to_string());
		//config.set_string_member("single_click_activate", single_click_activate.to_string());
		config.set_string_member("restore_last_session", restore_last_session.to_string());
		config.set_string_member("single_instance_mode", single_instance_mode.to_string());

		config.set_string_member("confirm_delete", confirm_delete.to_string());
		config.set_string_member("confirm_trash", confirm_trash.to_string());
		
		save_folder_selections();
		
		GtkBookmark.save_bookmarks();

		var json = new Json.Generator();
		json.pretty = true;
		json.indent = 2;
		var node = new Json.Node(NodeType.OBJECT);
		node.set_object(config);
		json.set_root(node);

		try {
			json.to_file(this.app_conf_path);
		} catch (Error e) {
			log_error (e.message);
		}

		set_numeric_locale(""); // reset numeric locale

		log_debug("\n" + _("App config saved") + ": '%s'".printf(app_conf_path));
	}

	public void load_app_config() {

		var f = File.new_for_path(app_conf_path);
		if (!f.query_exists()) {
			first_run = true;
			return;
		}

		var parser = new Json.Parser();
		try {
			parser.load_from_file(this.app_conf_path);
		}
		catch (Error e) {
			log_error (e.message);
		}

		var node = parser.get_root();
		var config = node.get_object();

		default_config = config;

		if (format_is_obsolete(config, Main.APP_CONFIG_FORMAT_VERSION)){
			first_run = true; // regard as first run
			return;
		}

		set_numeric_locale("C"); // switch numeric locale

		middlebar_visible = json_get_bool(config, "middlebar_visible", middlebar_visible);
		sidebar_visible = json_get_bool(config, "sidebar_visible", sidebar_visible);
		sidebar_dark = json_get_bool(config, "sidebar_dark", sidebar_dark);
		sidebar_places = json_get_bool(config, "sidebar_places", sidebar_places);
		sidebar_bookmarks = json_get_bool(config, "sidebar_bookmarks", sidebar_bookmarks);
		sidebar_devices = json_get_bool(config, "sidebar_devices", sidebar_devices);
		sidebar_position = json_get_int(config, "sidebar_position", sidebar_position);
		sidebar_unmount = json_get_bool(config, "sidebar_unmount", sidebar_unmount);
		sidebar_lock = json_get_bool(config, "sidebar_lock", sidebar_lock);

		headerbar_enabled = json_get_bool(config, "headerbar_enabled", headerbar_enabled);
		headerbar_enabled_temp = headerbar_enabled;
		
		show_hidden_files = json_get_bool(config, "show_hidden_files", show_hidden_files);
		panel_layout = (PanelLayout) json_get_int(config, "panel_layout", panel_layout);

		int vmode = json_get_int(config, "view_mode", view_mode);
		if (vmode >= 1 && vmode <= 4){
			view_mode = (ViewMode) vmode;
		}
		else{
			view_mode = ViewMode.LIST;
		}

		listview_font_scale = json_get_double(config, "listview_font_scale", LV_FONT_SCALE);
		listview_icon_size = json_get_int(config, "listview_icon_size", LV_ICON_SIZE);
		listview_row_spacing = json_get_int(config, "listview_row_spacing", LV_ROW_SPACING);
		listview_emblems = json_get_bool(config, "listview_emblems", listview_emblems);
		listview_thumbs = json_get_bool(config, "listview_thumbs", listview_thumbs);
		listview_transparency = json_get_bool(config, "listview_transparency", listview_transparency);

		iconview_icon_size = json_get_int(config, "iconview_icon_size", IV_ICON_SIZE);
		iconview_row_spacing = json_get_int(config, "iconview_row_spacing", IV_ROW_SPACING);
		iconview_column_spacing = json_get_int(config, "iconview_column_spacing", IV_COLUMN_SPACING);
		iconview_emblems = json_get_bool(config, "iconview_emblems", iconview_emblems);
		iconview_thumbs = json_get_bool(config, "iconview_thumbs", iconview_thumbs);
		iconview_transparency = json_get_bool(config, "iconview_transparency", iconview_transparency);

		tileview_icon_size = json_get_int(config, "tileview_icon_size", TV_ICON_SIZE);
		tileview_row_spacing = json_get_int(config, "tileview_row_spacing", TV_ROW_SPACING);
		tileview_padding = json_get_int(config, "tileview_padding", TV_PADDING);
		listview_emblems = json_get_bool(config, "listview_emblems", listview_emblems);
		listview_thumbs = json_get_bool(config, "listview_thumbs", listview_thumbs);
		listview_transparency = json_get_bool(config, "listview_transparency", listview_transparency);

		toolbar_visible = json_get_bool(config, "toolbar_visible", toolbar_visible);
		toolbar_large_icons = json_get_bool(config, "toolbar_large_icons", toolbar_large_icons);
		toolbar_dark = json_get_bool(config, "toolbar_dark", toolbar_dark);
		//toolbar_unified = json_get_bool(config, "toolbar_unified", toolbar_unified);
		toolbar_labels = json_get_bool(config, "toolbar_labels", toolbar_labels);
		toolbar_labels_beside_icons = json_get_bool(config, "toolbar_labels_beside_icons", toolbar_labels_beside_icons);

		toolbar_item_back = json_get_bool(config, "toolbar_item_back", toolbar_item_back);
		toolbar_item_next = json_get_bool(config, "toolbar_item_next", toolbar_item_next);
		toolbar_item_up = json_get_bool(config, "toolbar_item_up", toolbar_item_up);
		toolbar_item_reload = json_get_bool(config, "toolbar_item_reload", toolbar_item_reload);
		toolbar_item_home = json_get_bool(config, "toolbar_item_home", toolbar_item_home);
		toolbar_item_terminal = json_get_bool(config, "toolbar_item_terminal", toolbar_item_terminal);
		toolbar_item_hidden = json_get_bool(config, "toolbar_item_hidden", toolbar_item_hidden);
		toolbar_item_dual_pane = json_get_bool(config, "toolbar_item_dual_pane", toolbar_item_dual_pane);
		toolbar_item_view = json_get_bool(config, "toolbar_item_view", toolbar_item_view);
		toolbar_item_bookmarks = json_get_bool(config, "toolbar_item_bookmarks", toolbar_item_bookmarks);
		toolbar_item_devices = json_get_bool(config, "toolbar_item_devices", toolbar_item_devices);

		pathbar_unified = json_get_bool(config, "pathbar_unified", pathbar_unified);
		pathbar_use_buttons = json_get_bool(config, "pathbar_use_buttons", pathbar_use_buttons);
		pathbar_flat_buttons = json_get_bool(config, "pathbar_flat_buttons", pathbar_flat_buttons);
		pathbar_show_bookmarks = json_get_bool(config, "pathbar_show_bookmarks", pathbar_show_bookmarks);
		pathbar_show_disks = json_get_bool(config, "pathbar_show_disks", pathbar_show_disks);
		pathbar_show_back = json_get_bool(config, "pathbar_show_back", pathbar_show_back);
		pathbar_show_next = json_get_bool(config, "pathbar_show_next", pathbar_show_next);
		pathbar_show_up = json_get_bool(config, "pathbar_show_up", pathbar_show_up);
		pathbar_show_swap = json_get_bool(config, "pathbar_show_swap", pathbar_show_swap);
		pathbar_show_other = json_get_bool(config, "pathbar_show_other", pathbar_show_other);
		pathbar_show_close = json_get_bool(config, "pathbar_show_close", pathbar_show_close);

		statusbar_unified = json_get_bool(config, "statusbar_unified", statusbar_unified);

		tabs_bottom = json_get_bool(config, "tabs_bottom", tabs_bottom);
		tabs_close_visible = json_get_bool(config, "tabs_close_visible", tabs_close_visible);
		
		selected_columns = json_get_string(config, "selected_columns", selected_columns);
		selected_columns = selected_columns.replace(" ",""); // remove spaces

		maximise_on_startup = json_get_bool(config, "maximise_on_startup", maximise_on_startup);
		//single_click_activate = json_get_bool(config, "single_click_activate", single_click_activate);
		restore_last_session = json_get_bool(config, "restore_last_session", restore_last_session);
		single_instance_mode = json_get_bool(config, "single_instance_mode", single_instance_mode);

		confirm_delete = json_get_bool(config, "confirm_delete", confirm_delete);
		confirm_trash = json_get_bool(config, "confirm_trash", confirm_trash);

		middlebar_visible = json_get_bool(config, "middlebar_visible", middlebar_visible);
		sidebar_visible = json_get_bool(config, "sidebar_visible", sidebar_visible);
		sidebar_dark = json_get_bool(config, "sidebar_dark", sidebar_dark);
		sidebar_places = json_get_bool(config, "sidebar_places", sidebar_places);
		sidebar_bookmarks = json_get_bool(config, "sidebar_bookmarks", sidebar_bookmarks);
		sidebar_devices = json_get_bool(config, "sidebar_devices", sidebar_devices);
		sidebar_position = json_get_int(config, "sidebar_position", sidebar_position);
		sidebar_unmount = json_get_bool(config, "sidebar_unmount", sidebar_unmount);
		sidebar_lock = json_get_bool(config, "sidebar_lock", sidebar_lock);
		sidebar_collapsed_sections = json_get_string(config, "sidebar_collapsed_sections", sidebar_collapsed_sections);
		
		load_folder_selections();

		GtkBookmark.load_bookmarks(user_name, true);

		log_debug(_("App config loaded") + ": '%s'".printf(this.app_conf_path));

		set_numeric_locale(""); // reset numeric locale
	}


	public void save_folder_selections() {

		var config = new Json.Object();

		//if (archiver != null){
		//	config = archiver.to_json();
		//}

		set_numeric_locale("C"); // switch numeric locale

		config.set_int_member("format-version", (int64) APP_CONFIG_FOLDERS_FORMAT_VERSION);

		var included = new Json.Array();
		foreach(var path in mediaview_include){
			included.add_string_element(path);
		}
		config.set_array_member("mediaview_include", included);

		var excluded = new Json.Array();
		foreach(var path in mediaview_exclude){
			excluded.add_string_element(path);
		}
		config.set_array_member("mediaview_exclude", excluded);

		var json = new Json.Generator();
		json.pretty = true;
		json.indent = 2;
		var node = new Json.Node(NodeType.OBJECT);
		node.set_object(config);
		json.set_root(node);

		try {
			json.to_file(this.app_conf_folders);
		} catch (Error e) {
			log_error (e.message);
		}

		set_numeric_locale(""); // reset numeric locale

		log_debug("\n" + _("App config saved") + ": '%s'".printf(app_conf_folders));
	}

	public void load_folder_selections() {

		var f = File.new_for_path(app_conf_folders);
		if (!f.query_exists()) {
			//first_run = true; // don't set flag here
			return;
		}

		var parser = new Json.Parser();
		try {
			parser.load_from_file(this.app_conf_folders);
		}
		catch (Error e) {
			log_error (e.message);
		}

		var node = parser.get_root();
		var config = node.get_object();

		default_config = config;

		if (format_is_obsolete(config, Main.APP_CONFIG_FOLDERS_FORMAT_VERSION)){
			//first_run = true; // don't set
			return;
		}
		
		set_numeric_locale("C"); // switch numeric locale

		mediaview_include = json_get_array(config, "mediaview_include", mediaview_include);

		mediaview_exclude = json_get_array(config, "mediaview_exclude", mediaview_exclude);

		log_debug(_("App config loaded") + ": '%s'".printf(this.app_conf_folders));

		set_numeric_locale(""); // reset numeric locale
	}


	public void save_archive_selections(ArchiveTask task) {

		var config = new Json.Object();
		
		set_numeric_locale("C"); // switch numeric locale

		config.set_int_member("format-version", (int64) APP_CONFIG_ARCHIVE_FORMAT_VERSION);

		// begin ---------------------------

		config.set_string_member("format", task.format);
		config.set_string_member("method", task.method);
		config.set_string_member("level", task.level);
		config.set_string_member("dict_size", task.dict_size);
		config.set_string_member("word_size", task.word_size);
		config.set_string_member("block_size", task.block_size);
		config.set_string_member("passes", task.passes);
		config.set_string_member("encrypt_header", task.encrypt_header.to_string());
		config.set_string_member("encrypt_method", task.encrypt_method);
		//config.set_string_member("password", task.password);
		config.set_string_member("split_mb", task.split_mb);

		// end ---------------------------

		var json = new Json.Generator();
		json.pretty = true;
		json.indent = 2;
		var node = new Json.Node(NodeType.OBJECT);
		node.set_object(config);
		json.set_root(node);

		try {
			json.to_file(this.app_conf_archive);
		} catch (Error e) {
			log_error (e.message);
		}

		set_numeric_locale(""); // reset numeric locale

		log_debug("\n" + _("App config saved") + ": '%s'".printf(app_conf_archive));
	}

	public void load_archive_selections(ArchiveTask task) {

		var f = File.new_for_path(app_conf_archive);
		if (!f.query_exists()) {
			//first_run = true; // don't set flag here
			return;
		}

		var parser = new Json.Parser();
		try {
			parser.load_from_file(this.app_conf_archive);
		}
		catch (Error e) {
			log_error (e.message);
		}

		var node = parser.get_root();
		var config = node.get_object();

		if (format_is_obsolete(config, Main.APP_CONFIG_ARCHIVE_FORMAT_VERSION)){
			//first_run = true; // don't set
			return;
		}
		
		set_numeric_locale("C"); // switch numeric locale

		// begin ---------------------------

		task.format = json_get_string(config, "format", task.format);
		task.method = json_get_string(config, "method", task.method);
		task.level = json_get_string(config, "level", task.level);
		task.dict_size = json_get_string(config, "dict_size", task.dict_size);
		task.word_size = json_get_string(config, "word_size", task.word_size);
		task.block_size = json_get_string(config, "block_size", task.block_size);
		task.passes = json_get_string(config, "passes", task.passes);
		task.encrypt_header = json_get_bool(config, "encrypt_header", task.encrypt_header);
		task.encrypt_method = json_get_string(config, "encrypt_method", task.encrypt_method);
		task.split_mb = json_get_string(config, "split_mb", task.split_mb);
		
		// end ---------------------------
		
		log_debug(_("App config loaded") + ": '%s'".printf(this.app_conf_archive));

		set_numeric_locale(""); // reset numeric locale
	}

	public static bool format_is_obsolete(Json.Object node, int64 current_version){
		
		bool unsupported_format = false;
		
		if (node.has_member("format-version")){
			
			int format_version = (int) node.get_int_member("format-version");
			
			if (format_version < current_version){
				unsupported_format = true;
			}
		}
		else{
			unsupported_format = true;
		}

		return unsupported_format;
	}
	
	public void exit_app() {

		save_app_config();

		if (session_lock.lock_acquired){
			session_lock.remove();
		}

		try {
			//delete temporary files
			var f = File.new_for_path(temp_dir);
			if (f.query_exists()) {
				f.delete();
			}
		}
		catch (Error e) {
			log_error (e.message);
		}

		log_msg(_("Exiting Application"));
	}

	/* Core */

	public void clear_thumbnail_cache(){
		
		foreach(string dir in new string[] { "normal", "large", "fail" }){
			
			string cmd = "rm -rfv '%s/.cache/thumbnails/%s'".printf(escape_single_quote(App.user_home), dir);
			Posix.system(cmd);
			
			cmd = "mkdir -pv '%s/.cache/thumbnails/%s'".printf(escape_single_quote(App.user_home), dir);
			Posix.system(cmd);
		}
	}

	public static Gee.ArrayList<Device> get_devices(){

		var list = new Gee.ArrayList<Device>();

		foreach(var dev in Device.get_devices()){

			if ((dev.fstype.length == 0) && (dev.type == "part")){
				continue;
			}
			else if (dev.is_encrypted_partition && dev.has_children){
				continue;
			}
			else if (dev.is_snap_volume || dev.is_swap_volume){
				continue;
			}
			else{
				list.add(dev);
			}
		}

		return list;
	}

/*
	public void compress(FileItem _archive, bool wait = false) {
		archive_task.compress(_archive, wait);
	}

	public void extract(FileItem _archive, bool wait = false) {
		archive_task.extract(_archive, wait);
	}

	public void test(FileItem _archive, bool wait = false) {
		// create a unique temporary extraction directory
		archive_task.extraction_path = "%s/%s".printf(App.temp_dir,random_string());
		dir_create(archive_task.extraction_path);

		// begin
		archive_task.test(_archive, wait);
	}

	public void open(FileItem archive, bool wait = false) {

	}

	public void open_info(FileItem _archive, bool wait = false) {
		archive_task.archive = _archive;
		archive_task.open_info(_archive, wait);
	}

	
	public void set_extraction_path_from_args(){

		// set extraction path

		if (arg_same_path){
			// select a subfolder in source path for extraction
			archive_task.extraction_path = "%s/%s".printf(
				file_parent(archive.file_path),
				file_basename(archive.file_path).split(".")[0]);

			// since user has not specified the directory we need to
			// make sure that files are not overwritten accidentally
			// in existing directories 

			// create a unique extraction directory
			int count = 0;
			string outpath = archive_task.extraction_path;
			while (dir_exists(outpath)||file_exists(outpath)){
				log_debug("dir_exists: %s".printf(outpath));
				outpath = "%s (%d)".printf(archive_task.extraction_path, ++count);
			}
			log_debug("create_dir: %s".printf(outpath));
			archive_task.extraction_path = outpath;
		}
		else if (arg_prompt_outpath){
			// do nothing
		}
		else {
			// set path specified on command line
			archive_task.extraction_path = arg_outpath;
		}
	}

	public FileItem new_archive() {
		var archive = new FileItem();
		archive_task.action = ArchiveAction.CREATE;
		return archive;
	}

	public string get_random_password(){
		string stdout, stderr;
		exec_script_sync("head /dev/urandom | tr -dc 'a-zA-Z0-9-_!@#$%^&*()_+{}|:<>?=' | head -c 20", out stdout, out stderr, true);
		return stdout;
	}*/
}

public enum AppMode {
	NEW,
	CREATE,
	OPEN,
	TEST,
	EXTRACT
}

public enum PanelLayout{
	SINGLE = 1,
	DUAL_VERTICAL = 2,
	DUAL_HORIZONTAL = 3,
	QUAD = 4,
	CUSTOM = 5
}

public enum ViewMode{
	LIST = 1,
	ICONS = 2,
	TILES = 3,
	MEDIA = 4
}