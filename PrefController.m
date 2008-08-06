/*
 This file is part of TextForge.
 
 TextForge is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 TextForge is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with TextForge; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 
 Copyright (c) 2003-2004 Trance Software.
 */

#import "PrefController.h"
#import <PreferencePanes/NSPreferencePane.h>
#import "tfTextView.h"
#import "MyDocument.h"
#import "MyDocumentController.h"

static PrefController *sharedInstance = nil;

@implementation PrefController

+(PrefController*)sharedInstance {
  return sharedInstance ? sharedInstance : [[self alloc] init];
}

-(id)init {
  if (sharedInstance) {
    [self dealloc];
  }
  else {
    sharedInstance = [super init];
  }
  return sharedInstance;
}

-(void)awakeFromNib {
  unsigned i = 0;
  NSBundle *bundle = nil;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fontPanelRequested:) name:@"FontPanelRequested" object:nil];
  NSToolbar *toolbar=[[[NSToolbar alloc] initWithIdentifier:@"PreferenceToolbar"] autorelease];
  
  NSString *bundlePath = [NSString stringWithFormat:@"%@/Contents/Resources/PreferencePanes", [[NSBundle mainBundle] bundlePath]];
  panes = [[[NSFileManager defaultManager] directoryContentsAtPath:bundlePath] mutableCopy];
  
  for ( i = 0; i < [panes count]; i++ ) {
	bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/%@", bundlePath, [panes objectAtIndex:i]]];
	[bundle load];
	if( bundle ) {
	  [panes replaceObjectAtIndex:i withObject:bundle];
	}  
	else {
	  [panes removeObjectAtIndex:i];
	  i--;
	}
  }
  loadedPanes = [[NSMutableDictionary dictionary] retain];
  
  [window setDelegate:self];
  
  [toolbar setDelegate:self];
  [toolbar setAllowsUserCustomization:NO];
  [toolbar setAutosavesConfiguration: NO];
  
  [window setToolbar:toolbar];
  [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
}

-(IBAction)showWindow:(id)sender {
  if(!window) {
	[NSBundle loadNibNamed:@"PreferenceWindow" owner:self];
  }
  NSArray *toolbarItems = [[window toolbar] items];
  if([toolbarItems count] != 0) {
    NSString *itemId = [[toolbarItems objectAtIndex:0] itemIdentifier];
	[self displayPane: itemId];
	[[window toolbar] setSelectedItemIdentifier: itemId];
	[window makeKeyAndOrderFront:nil];
  } else {
    NSBeep();
  }
}

-(IBAction)selectPane:(id)sender {
  [self displayPane:[sender itemIdentifier]];
}

-(void)displayPane:(NSString *)identifier {
  NSBundle *bundle = [NSBundle bundleWithIdentifier: identifier];
  if(bundle && ![currentPaneIdentifier isEqualToString: identifier]) {
	NSView *prefView;
	NSPreferencePane *pane;
	  
    if (!(pane = [loadedPanes objectForKey:identifier])) {
	  pane = [[[[bundle principalClass] alloc] initWithBundle:bundle] autorelease];
	  if( pane ) [loadedPanes setObject:pane forKey:identifier];
	}
	  
	if([pane loadMainView]) {
	  [pane willSelect];
	  prefView = [pane mainView];
	  [window setTitle:[self labelForPaneBundle:bundle]];
	  [window setContentView:loadingView];
	  [window display];
	  NSRect windowFrame = [NSWindow contentRectForFrameRect:[window frame] styleMask:[window styleMask]];
	  float  newWindowHeight = NSHeight([prefView frame]);
	  float toolbarHeight = 0.0;
	  if([window toolbar] && [[window toolbar] isVisible]) {
	    toolbarHeight = NSHeight(windowFrame) - NSHeight([[window contentView] frame]);
	  }
	  if ([[window toolbar] isVisible]) newWindowHeight += toolbarHeight;
	  NSRect newWindowFrame = [NSWindow frameRectForContentRect:NSMakeRect( NSMinX( windowFrame ), NSMaxY( windowFrame ) - newWindowHeight, NSWidth( windowFrame ), newWindowHeight ) styleMask:[window styleMask]];
	  [window setFrame:newWindowFrame display:YES animate:[window isVisible]];
	  [[loadedPanes objectForKey:currentPaneIdentifier] willUnselect];
	  [window setContentView: prefView];
	  [[loadedPanes objectForKey:currentPaneIdentifier] didUnselect];
	  [pane didSelect];
	  [currentPaneIdentifier autorelease];
	  currentPaneIdentifier = [identifier copy];
	}
  }
}

- (NSString *)labelForPaneBundle:(NSBundle *) bundle {
  NSDictionary *paneInfo = [bundle infoDictionary];
  return [paneInfo valueForKey:@"NSPrefPaneIconLabel"];
}

-(NSImage *)imageForPaneBundle:(NSBundle *)bundle {
  NSImage *image = nil;
  NSDictionary *info = [bundle infoDictionary];
  NSString *string = [info objectForKey:@"NSPrefPaneIconFile"];
  image = [[[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:string]] autorelease];
  return image;
}	

-(NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
  NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
  NSBundle *bundle = [NSBundle bundleWithIdentifier:itemIdentifier];
  if(bundle) {
    [toolbarItem setLabel:[self labelForPaneBundle:bundle]];
	[toolbarItem setPaletteLabel:[self labelForPaneBundle:bundle]];
	[toolbarItem setImage:[self imageForPaneBundle:bundle]];
	[toolbarItem setTarget:self];
	[toolbarItem setAction:@selector( selectPane: )];
  } else {
    toolbarItem = nil;
  }
  return toolbarItem;
}

    
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
  NSArray *defaults = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PreferencePaneDefaults" ofType:@"plist"]];
  return defaults;
}

- (NSArray *) toolbarAllowedItemIdentifiers:(NSToolbar *) toolbar {
  NSArray *defaults = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PreferencePaneDefaults" ofType:@"plist"]];
  return defaults;
}

- (void)changeFont:(id)fontManager {
  NSArray *docs = [[MyDocumentController sharedInstance] documents];
  tfTextView *temp;
  int i;
  [NSFont setUserFixedPitchFont:[fontManager convertFont:[NSFont userFixedPitchFontOfSize:0.0]]];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"FontChanged" object:[NSFont userFixedPitchFontOfSize:0.0]];
  // change font in all existing windows now
  for (i = 0; i < [docs count]; i++) {
    temp = [[docs objectAtIndex:i] getTextView];
    [temp setFont:[NSFont userFixedPitchFontOfSize:0.0]];
    [temp display];
  }
}

// Font panel should close if prefs window closes
-(void)windowWillClose:(NSNotification *)aNotification {
  if ([[NSFontPanel sharedFontPanel] isVisible]) {
    [[NSFontPanel sharedFontPanel] close];
  }
}

// Font panel should close if prefs window is not main
- (void)windowDidResignMain:(NSNotification *)aNotification {
  if ([aNotification object] == window) {
    if ([[NSFontPanel sharedFontPanel] isVisible]) {
      [[NSFontPanel sharedFontPanel] close];
    }
  }
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
  return [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PreferencePaneDefaults" ofType:@"plist"]];
}

-(void)dealloc {
  [super dealloc];
}

@end
