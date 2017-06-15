// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

  Copyright (C) 2013 Julien Spautz <spautz.julien@gmail.com>
  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE.  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program.  If not, see <http://www.gnu.org/licenses/>

  END LICENSE
***/

namespace Scratch.Plugins.FolderManager {
    /**
     * Expandable item in the source list, represents a folder.
     * Monitored for changes inside the directory.
     * TODO remove, rename, create new file
     */
    internal class FolderItem : Item {

        //Gtk.Menu menu;
        //Gtk.MenuItem item_trash;
        //Gtk.MenuItem item_create;

        private GLib.FileMonitor monitor;
        private bool children_loaded = false;

        public FolderItem (File file) requires (file.is_valid_directory) {
            Object (file: file);

            this.editable = false;
            this.selectable = false;
            this.name = file.name;
            this.icon = file.icon;

            this.add (new Granite.Widgets.SourceList.Item ("")); // dummy
            this.toggled.connect (() => {
                if (this.expanded && this.n_children <= 1) {
                    this.clear ();
                    this.add_children ();
                    children_loaded = true;
                }
            });

            try {
                monitor = file.file.monitor_directory (GLib.FileMonitorFlags.NONE);
                monitor.changed.connect ((s,d,e) => { on_changed (s,d,e); });
            } catch (GLib.Error e) {
                warning (e.message);
            }
        }

        /*public override Gtk.Menu? get_context_menu () {
            menu = new Gtk.Menu ();
            item_trash = new Gtk.MenuItem.with_label (_("Move to Trash"));
            item_create = new Gtk.MenuItem.with_label (_("Create new File"));
            menu.append (item_trash);
            menu.append (item_create);
            item_trash.activate.connect (() => { file.trash (); });
            item_create.activate.connect (() => {
                var new_file = GLib.File.new_for_path (file.path + "/new File");

                try {
		            FileOutputStream os = new_file.create (FileCreateFlags.NONE);
	            } catch (Error e) {
		            warning ("Error: %s\n", e.message);
	            }
            });
            menu.show_all ();
            return menu;
        }*/

        internal void add_children () {
            foreach (var child in file.children) {
                if (child.is_valid_directory) {
                    var item = new FolderItem (child);
                    add (item);
                } else if (child.is_valid_textfile) {
                    var item = new FileItem (child);
                    add (item);
                    //item.edited.connect (item.rename);
                }
            }
        }

        private void on_changed (GLib.File source, GLib.File? dest, GLib.FileMonitorEvent event) {

            if (!children_loaded) {
                this.file.reset_cache ();
                return;
            }

            switch (event) {
                case GLib.FileMonitorEvent.DELETED:
                    var children_tmp = new Gee.ArrayList<Granite.Widgets.SourceList.Item> ();
                    children_tmp.add_all (children);
                    foreach (var item in children_tmp) {
                        if ((item as Item).path == source.get_path ()) {
                            remove (item);
                        }
                    }

                    break;
                case GLib.FileMonitorEvent.CREATED:
                    if (source.query_exists () == false) {
                        return;
                    }

                    var file = new File (source.get_path ());
                    var exists = false;
                    foreach (var item in children) {
                        if ((item as Item).path == file.path) {
                            exists = true;
                            break;
                        }
                    }

                    if (!exists) {
                        if (file.is_valid_textfile) {
                            this.add (new FileItem (file));
                        } else if (file.is_valid_directory) {
                            this.add (new FolderItem (file));
                        }
                    }

                    break;
            }
        }
    }
}