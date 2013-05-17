//
//  ZDYoutubeBrowser.m
//  ZDYoutubeBrowserApp
//
//  Created by zedoul on 5/17/13.
//  Copyright (c) 2013 scipi. All rights reserved.
//

#import "ZDYoutubeBrowser.h"

#import "MGBox.h"
#import "MGScrollView.h"

#import "JSONModelLib.h"
#import "VideoModel.h"

#import "PhotoBox.h"
#import "WebVideoViewController.h"

@interface ZDYoutubeBrowser () <UISearchBarDelegate>
{
    IBOutlet MGScrollView* scroller;
    MGBox* searchBox;
    
    NSArray* videos;
}

@end

@implementation ZDYoutubeBrowser

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //setup the scroll view
    scroller.contentLayoutMode = MGLayoutGridStyle;
    scroller.bottomPadding = 8;
    scroller.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1];
    
    //setup the search box
    searchBox = [MGBox boxWithSize:CGSizeMake(320,44)];
    searchBox.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1];
    
    //setup the search text field
    /*
    UITextField* fldSearch = [[UITextField alloc] initWithFrame:CGRectMake(4,4,312,35)];
    fldSearch.borderStyle = UITextBorderStyleRoundedRect;
    fldSearch.backgroundColor = [UIColor whiteColor];
    fldSearch.font = [UIFont systemFontOfSize:24];
    fldSearch.delegate = self;
    fldSearch.placeholder = @"Search YouTube...";
    fldSearch.text = @"";
    fldSearch.clearButtonMode = UITextFieldViewModeAlways;
    fldSearch.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [searchBox addSubview: fldSearch];
    */
    
    //add search box
    //[scroller.boxes addObject:searchBox];
    
    //fire up the first search
    [self searchYoutubeVideosForTerm:@""];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//fire up API search on Enter pressed
/*
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self searchYoutubeVideosForTerm:textField.text];
    return YES;
}
 */

-(void)searchYoutubeVideosForTerm:(NSString*)term
{
    NSLog(@"Searching for '%@' ...", term);
    
    //URL escape the term
    term = [term stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //make HTTP call
    NSString* searchCall = [NSString stringWithFormat:@"http://gdata.youtube.com/feeds/api/videos?q=%@&max-results=50&alt=json", term];
    
    [JSONHTTPClient getJSONFromURLWithString: searchCall
                                  completion:^(NSDictionary *json, JSONModelError *err) {
                                      
                                      //got JSON back
                                      NSLog(@"Got JSON from web: %@", json);
                                      
                                      if (err) {
                                          [[[UIAlertView alloc] initWithTitle:@"Error"
                                                                      message:[err localizedDescription]
                                                                     delegate:nil
                                                            cancelButtonTitle:@"Close"
                                                            otherButtonTitles: nil] show];
                                          return;
                                      }
                                      
                                      //initialize the models
                                      videos = [VideoModel arrayOfModelsFromDictionaries:
                                                json[@"feed"][@"entry"]
                                                ];
                                      
                                      if (videos) NSLog(@"Loaded successfully models");
                                      
                                      //show the videos
                                      [self showVideos];
                                      
                                  }];
}

-(void)showVideos
{
    //clean the old videos
//    [scroller.boxes removeObjectsInRange:NSMakeRange(1, scroller.boxes.count-1)];
    
    //add boxes for all videos
    for (int i=0;i<videos.count;i++) {
        
        //get the data
        VideoModel* video = videos[i];
        MediaThumbnail* thumb = video.thumbnail[0];
        
        //create a box
        PhotoBox *box = [PhotoBox photoBoxForURL:thumb.url title:video.title];
        box.onTap = ^{
            WebVideoViewController* det = [[WebVideoViewController alloc]
                                     initWithNibName:@"WebVideoViewController" bundle:nil];
            det.video = video;
            [self.navigationController pushViewController:det animated:NO];
        };
        
        //add the box
        [scroller.boxes addObject:box];
    }
    
    //re-layout the scroll view
    [scroller layoutWithSpeed:0.3 completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    WebVideoViewController* controller = segue.destinationViewController;
    controller.video = sender;
}

#pragma mark - UISearchDisplayController Delegate Methods
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
//    self.queryString = [searchText retain];
//    self.queryStringLabel.text = self.queryString;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)sBar
{
    searchBar.showsCancelButton = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)sBar
{
    searchBar.showsCancelButton = NO;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)sBar
{
    [self searchYoutubeVideosForTerm:sBar.text];
    /*
    if([delegate respondsToSelector:@selector(searchResultViewControllerDidEntered:)]) {
        [delegate searchResultViewControllerDidEntered:self.queryString];
    }
    
    [self fetchSearchResults];
    [searchBar resignFirstResponder];
    [self displayImages:YES];
    [self.scrollView setNeedsDisplay];
     */
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)sBar
{
    [searchBar resignFirstResponder];
    searchBar.showsCancelButton =NO;
    
    if([_delegate respondsToSelector:@selector(youtubeBrowserDidClose:)]) {
        [_delegate youtubeBrowserDidClose:self];
    }
}

@end