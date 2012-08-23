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

- (void)refreshButtonTapped:(id)sender;

/** Reload current movies from JSON */
- (void)reloadMovies;

@end

@implementation ListViewController

- (void)refreshButtonTapped:(id)sender {
	[self reloadMovies];
}

- (void)reloadMovies {
	NSString *jsonURLString = @"https://dl.dropbox.com/u/6840433/Biograf/zitkino.json";
	NSURL *jsonURL = [NSURL URLWithString:jsonURLString];
	FSNConnection *connection = [FSNConnection withUrl:jsonURL method:FSNRequestMethodGET headers:nil parameters:nil parseBlock:^id(FSNConnection *c, NSError **error) {
		return [c.responseData dictionaryFromJSONWithError:error];
	} completionBlock:^(FSNConnection *connection) {
		
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		
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
		
		// reload table
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[self.tableView reloadData];
		}];
		
		
	} progressBlock:nil];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	[connection start];
}

- (void)loadView {
	[super loadView];
	
	self.title = @"Biograf";
	
	// add refresh button
	UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped:)];
	self.navigationItem.rightBarButtonItem = reloadButton;
}

- (void)viewDidLoad {
	[super viewDidLoad];
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
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

@end
