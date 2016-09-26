import sublime
import sublime_plugin
import subprocess
import re
import time
import threading

class CommandOnSave(sublime_plugin.EventListener):
    def __init__(self):
        self.timeout = 2
        self.timer = None

    def cancel_timer(self):
        if self.timer != None:
            self.timer.cancel()

    def start_timer(self):
        self.timer = threading.Timer(self.timeout, self.clear)
        self.timer.start()

    def clear(self):
        print("Command on Save Cleared")
        self.timer = None

    def on_post_save(self, view):
        view.erase_status('command_on_save')

        settings = sublime.load_settings('CommandOnSave.sublime-settings').get('commands')
        enabled = sublime.load_settings('CommandOnSave.sublime-settings').get('enabled')
        file = view.file_name()

        if self.timer == None and not settings == None and not enabled == None and enabled == True:
            for path in settings.keys():
                commands = settings.get(path)
                match = re.match(path, file, re.M|re.I)
                if match and len(commands) > 0:
                    print("Command on Save:")
                    for command in commands:
                        p = subprocess.Popen([command], shell=True, stdout=subprocess.PIPE)
                        out, err = p.communicate()
                        print (command)
                        print (out.decode('utf-8'))
                        self.start_timer()

class ToggleCommandOnSave(sublime_plugin.ApplicationCommand):
    def __init__(self):
        self.timeout = 3
        self.timer = None

    def run(self):
        settings = sublime.load_settings("CommandOnSave.sublime-settings")
        value = True if settings.get("enabled", True) != True else False
        if value:
            sublime.active_window().active_view().set_status('command_on_save', "[Command on Save Enabled]")
        else:
            sublime.active_window().active_view().set_status('command_on_save', "[Command on Save Disabled]")
        settings.set("enabled", value)
        self.start_timer()
        # sublime.save_settings("CommandOnSave.sublime-settings")

    def cancel_timer(self):
        if self.timer != None:
            self.timer.cancel()

    def start_timer(self):
        self.timer = threading.Timer(self.timeout, self.clear)
        self.timer.start()

    def clear(self):
        sublime.active_window().active_view().erase_status("command_on_save")
