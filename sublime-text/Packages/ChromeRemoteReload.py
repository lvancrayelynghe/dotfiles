import sublime, sublime_plugin, os, subprocess

class ChromeRemoteReloadCommand(sublime_plugin.TextCommand):
	def run(self, edit):
		p = subprocess.Popen('chrome-remote-reload', stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
		result, err = p.communicate()
