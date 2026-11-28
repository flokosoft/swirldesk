#!/usr/bin/env python3
"""Local GTK3 session menu. Authentication stays with KScreenLocker/logind."""
import subprocess
import shutil
from pathlib import Path
import gi
gi.require_version('Gtk','3.0')
from gi.repository import Gtk, Gdk, Gio
HERE = Path(__file__).resolve().parent
ACTIONS = (
    ('01', 'LOCK TERMINAL', 'Lock current session', 'lock', 'loginctl'),
    ('02', 'SUSPEND CONNECTION', 'Suspend computer', 'suspend', 'systemctl'),
    ('03', 'DISCONNECT', 'Log out of Plasma — unsaved work may be lost', 'logout', 'qdbus6'),
    ('04', 'REINITIALIZE', 'Restart computer — save your work first', 'reboot', 'systemctl'),
    ('05', 'SYSTEM SHUTDOWN', 'Power off computer — save your work first', 'shutdown', 'systemctl'),
)
class Power(Gtk.Application):
    def __init__(self):
        super().__init__(application_id='org.swirldesk.MatrixPlasmaSession', flags=Gio.ApplicationFlags.FLAGS_NONE)
        self.win = None
    def do_activate(self):
        if self.win is not None:
            self.win.present(); return
        self.win = Gtk.ApplicationWindow(application=self, title='MATRIX SESSION')
        self.win.set_default_size(490, 430)
        self.win.set_position(Gtk.WindowPosition.CENTER)
        self.win.get_style_context().add_class('matrix')
        self.win.connect('destroy', lambda *_: setattr(self, 'win', None))
        self.win.connect('key-press-event', self.key)
        css = Gtk.CssProvider(); css.load_from_path(str(HERE.parent/'control/operator.css'))
        Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), css, 800)
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8, margin=12); self.win.add(box)
        title = Gtk.Label(label='MATRIX // SESSION CONTROL', xalign=0); title.get_style_context().add_class('headline'); box.pack_start(title,False,False,0)
        sub = Gtk.Label(label='LOCAL SESSION / SELECT OPERATOR COMMAND', xalign=0); sub.get_style_context().add_class('muted'); box.pack_start(sub,False,False,0)
        for number, name, desc, action, cmd in ACTIONS:
            btn=Gtk.Button(); content=Gtk.Box(orientation=Gtk.Orientation.VERTICAL,spacing=4)
            head=Gtk.Label(label=f'{number} // {name}',xalign=0); head.get_style_context().add_class('section-title'); content.pack_start(head,False,False,0)
            detail=Gtk.Label(label=desc,xalign=0); detail.set_line_wrap(True); detail.get_style_context().add_class('muted'); content.pack_start(detail,False,False,0)
            btn.add(content); btn.set_sensitive(bool(shutil.which(cmd))); btn.connect('clicked',self.select,action,name); box.pack_start(btn,True,True,0)
        cancel=Gtk.Button(label='ESC // CANCEL'); cancel.connect('clicked',lambda *_: self.win.destroy()); box.pack_start(cancel,False,False,0)
        self.win.show_all(); cancel.grab_focus()
    def key(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            widget.destroy(); return True
        return False
    def select(self, button, action, name):
        args=[str(HERE/'action.sh'),action]
        if action != 'lock':
            dialog=Gtk.MessageDialog(transient_for=self.win,modal=True,message_type=Gtk.MessageType.WARNING,buttons=Gtk.ButtonsType.NONE,text=f'CONFIRM // {name}')
            dialog.get_style_context().add_class('matrix')
            dialog.format_secondary_text('Save any open work before continuing. This command affects the current computer/session.')
            dialog.add_button('CANCEL', Gtk.ResponseType.CANCEL); dialog.add_button('CONFIRM',Gtk.ResponseType.OK); dialog.set_default_response(Gtk.ResponseType.CANCEL)
            response=dialog.run(); dialog.destroy()
            if response != Gtk.ResponseType.OK: return
            args.append('--confirmed')
        try:
            # Delegate to the existing session tools, never read credentials here.
            subprocess.Popen(args, start_new_session=True)
        except OSError as exc:
            dialog=Gtk.MessageDialog(transient_for=self.win,modal=True,message_type=Gtk.MessageType.ERROR,buttons=Gtk.ButtonsType.CLOSE,text=str(exc)); dialog.run(); dialog.destroy(); return
        self.win.destroy()
if __name__ == '__main__':
    raise SystemExit(Power().run(None))
