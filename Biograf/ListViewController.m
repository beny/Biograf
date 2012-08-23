//
//  ListViewController.m
//  Biograf
//
//  Created by Ondra Beneš on 8/23/12.
//  Copyright (c) 2012 Ondra Beneš. All rights reserved.
//

#import "ListViewController.h"

#import "FSNConnection.h"
#import "JSONKit.h"

@interface ListViewController ()

// TODO comment
@property (nonatomic, strong) NSMutableArray *movies;
@property (nonatomic, strong) UIBarButtonItem *refreshButton;

- (void)refreshButtonTapped:(id)sender;

/** Reload current movies from JSON */
- (void)reloadMovies;

@end

@implementation ListViewController

- (void)refreshButtonTapped:(id)sender {
	[self reloadMovies];
}

- (void)reloadMovies {
	NSString *jsonURLString = @"http://zitkino.cz/zitkino.json";
	NSURL *jsonURL = [NSURL URLWithString:jsonURLString];
	FSNConnection *connection = [FSNConnection withUrl:jsonURL method:FSNRequestMethodGET headers:nil parameters:nil parseBlock:^id(FSNConnection *c, NSError **error) {
		return [c.responseData dictionaryFromJSONWithError:error];
	} completionBlock:^(FSNConnection *connection) {
		
		
		
		NSDictionary *result = (NSDictionary *)connection.parseResult;
		NSArray *data = [result objectForKey:@"data"];
		
		self.movies = [NSMutableArray array];
		
		for (NSDictionary *movie in data) {
			NSDictionary *localMovie = [[self.movies lastObject] lastObject];
			if ([[localMovie objectForKey:@"date"] isEqualToString:[movie objectForKey:@"date"]]) {
				[[self.movies lastObject] addObject:movie];
			}
			else {
				[self.movies addObject:[NSMutableArray array]];
				[[self.movies lastObject] addObject:movie];
			}
		}
		
		// save to device
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:self.movies forKey:@"data"];
		[defaults synchronize];
		
		// reload table
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
			self.refreshButton.enabled = YES;
			[self.tableView reloadData];
		}];
		
		
	} progressBlock:nil];
	
	[connection start];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	self.refreshButton.enabled = NO;
	
}

- (void)loadView {
	[super loadView];
	
	// view controller attributes
	self.title = @"Biograf";
	self.navigationController.navigationBar.tintColor = UIColorFromRGB(0x5343ba);
	
	// add refresh button
	self.refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped:)];
	self.navigationItem.rightBarButtonItem = self.refreshButton;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	// load from store
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	self.movies = [defaults objectForKey:@"data"];
	[self.tableView reloadData];

	[self reloadMovies];
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.movies.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[self.movies objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = @"yyyy-MM-dd";
	NSString *dateString = [[[self.movies objectAtIndex:section] lastObject] objectForKey:@"date"];
	BOOL isToday = [dateString isEqualToString:[dateFormatter stringFromDate:[NSDate date]]];
	NSDate *date = [dateFormatter dateFromString:dateString];
	dateFormatter.dateFormat = @"EEEE, d.M";
	return isToday ? @"Dnes" : [dateFormatter stringFromDate:date];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *movieCellIdentifier = @"movieCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:movieCellIdentifier];
    if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:movieCellIdentifier];
	}
	
	NSDictionary *movie = [[self.movies objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	cell.textLabel.text = [[movie objectForKey:@"title"] capitalizedString];
	cell.detailTextLabel.text = [movie objectForKey:@"cinema"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

@end
