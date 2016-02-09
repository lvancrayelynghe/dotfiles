#!/usr/bin/python
# An application starter.

import gobject
import gtk
import appindicator
import os
import pynotify
import sys
import shlex
import re

_SETTINGS_FILE = os.getenv("HOME") + "/.appstarter"

def parseMenuItem(w, item):
    if item == '_refresh':
        newmenu = buildMenu()
        ind.set_menu(newmenu)
        pynotify.init("appstarter")
        pynotify.Notification("AppStarter refreshed", "Menu list was refreshed from %s" % _SETTINGS_FILE).show()
    elif item == '_quit':
        sys.exit(0)
    elif item == 'folder':
        pass
    else:
        print item
        os.spawnvp(os.P_NOWAIT, item['cmd'], [item['cmd']] + item['args'])
        os.wait3(os.WNOHANG)

def showErrorDialog(msg):
    md = gtk.MessageDialog(None, 0, gtk.MESSAGE_ERROR, gtk.BUTTONS_OK)
    try:
        md.format_secondary_markup(msg)
        md.run()
    finally:
        md.destroy()

def addSeparator(menu):
    separator = gtk.SeparatorMenuItem()
    separator.show()
    menu.append(separator)

def addMenuItem(menu, caption, item=None):
    menu_item = gtk.MenuItem(caption)
    if item:
        menu_item.connect("activate", parseMenuItem, item)
    else:
        menu_item.set_sensitive(False)
    menu_item.show()
    menu.append(menu_item)
    return menu_item

def getConfigFromFile():
    if not os.path.exists(_SETTINGS_FILE):
        return []

    app_list = []
    f = open(_SETTINGS_FILE, "r")
    try:
        for line in f.readlines():
            line = line.rstrip()
            if not line or line.startswith('#'):
                continue
            elif line == "---":
                app_list.append('---')
            elif line.startswith('label:'):
                app_list.append({
                    'name': 'LABEL',
                    'cmd': line[6:],
                    'args': ''
                })
            elif line.startswith('folder:'):
                app_list.append({
                    'name': 'FOLDER',
                    'cmd': line[7:],
                    'args': ''
                })
            else:
                try:
                    name, cmd, args = line.split('|', 2)
                    app_list.append({
                        'name': name,
                        'cmd': cmd,
                        'args': [n.replace("\n", "") for n in shlex.split(args)],
                    })
                except ValueError:
                    print "The following line has errors and will be ignored:\n%s" % line
    finally:
        f.close()
    return app_list

def buildMenu():
    if not os.path.exists(_SETTINGS_FILE) :
        showErrorDialog("<b>ERROR: No config file found in home directory</b>")
        sys.exit(1)

    app_list = getConfigFromFile()
    menu = gtk.Menu()
    menus = [menu]

    for app in app_list:
        if app == "---":
            addSeparator(menus[-1])
        elif app['name'] == "FOLDER" and not app['cmd']:
            if len(menus) > 1:
                menus.pop()
        elif app['name'] == "FOLDER":
            menu_item = addMenuItem(menus[-1], app['cmd'], 'folder')
            menus.append(gtk.Menu())
            menu_item.set_submenu(menus[-1])
        elif app['name'] == "LABEL":
            addMenuItem(menus[-1], app['cmd'], None)
        else:
            addMenuItem(menus[-1], app['name'], app)

    addSeparator(menu)
    addMenuItem(menu, 'Refresh', '_refresh')
    addMenuItem(menu, 'Quit', '_quit')
    return menu

if __name__ == "__main__":
    ind = appindicator.Indicator("appstarter", "emblem-desktop", appindicator.CATEGORY_APPLICATION_STATUS)
    ind.set_status(appindicator.STATUS_ACTIVE)

    appmenu = buildMenu()
    ind.set_menu(appmenu)
    gtk.main()
