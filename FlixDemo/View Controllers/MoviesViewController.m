//
//  MoviesViewController.m
//  FlixDemo
//
//  Created by jordan487 on 6/26/19.
//  Copyright © 2019 jordan487. All rights reserved.
//

#import "MoviesViewController.h"
#import "MovieCell.h"
#import "UIImageView+AFNetworking.h"
#import "DetailsViewController.h"

@interface MoviesViewController () <UITableViewDataSource, UITableViewDataSource>

@property (nonatomic, strong) NSArray *movies;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSArray *filteredData;

@end

@implementation MoviesViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    
    [self fetchMovies];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchMovies) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
    
    // Search bar
    // Initializing with searchResultsController set to nil means that
    // searchController will use this view controller to display the search results
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    
    // If we are using this same view controller to present the results
    // dimming it out wouldn't make sense. Should probably only set
    // this to yes if using another controller to display the search results.
    self.searchController.dimsBackgroundDuringPresentation = NO;
    
    [self.searchController.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    
    // Sets this view controller as presenting view controller for the search interface
    self.definesPresentationContext = YES;
    
}

- (void) fetchMovies {
    
    // Start the activity indicator
    [self.activityIndicator startAnimating];

    // Do any additional setup after loading the view.
    
    NSURL *url = [NSURL URLWithString:@"https://api.themoviedb.org/3/movie/now_playing?api_key=a07e22bc18f5cb106bfe4cc1f83ad8ed"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Network Connection" message:@"Get Some better Wifi bro" preferredStyle:(UIAlertControllerStyleAlert)];
            
            /*
            // create a cancel action
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                // handle cancel response here. Doing nothing will dismiss the view.
            }];
            // add the cancel action to the alertController
            [alert addAction:cancelAction];
            */
            
            // create an OK action
            UIAlertAction *tryAgainAction = [UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                // handle response here.
            }];
            // add the OK action to the alert controller
            [alert addAction:tryAgainAction];
            
            [self presentViewController:alert animated:YES completion:^{
                // optional code for what happens after the alert controller has finished presenting
            }];
            
            NSLog(@"%@", [error localizedDescription]);
            [self viewDidLoad];
            
        }
        else {
            NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            //NSLog(@"%@", dataDictionary);
            
            self.movies = dataDictionary[@"results"];
            self.filteredData = self.movies;
//            for (NSDictionary *movie in self.movies) {
//                NSLog(@"%@", movie[@"title"]);
//            }
            
            [self.tableView reloadData];
            
            // Stop the activity indicator
            // Hides automatically if "Hides When Stopped" is enabled
            [self.activityIndicator stopAnimating];
            
        }
        [self.refreshControl endRefreshing];
    }];
    [task resume];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MovieCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MovieCell"];
    
    NSDictionary *movie = self.filteredData[indexPath.row];
    cell.titleLabel.text = movie[@"title"];
    cell.synopsysLabel.text = movie[@"overview"];
    cell.movieRatingsLabel.text = [NSString stringWithFormat:@"%@ / 10", movie[@"vote_average"]];
    
    NSString *baseURLString = @"https://image.tmdb.org/t/p/w500";
    NSString *posterURLString = movie[@"poster_path"];
    NSString *fullPosterURLString = [baseURLString stringByAppendingString:posterURLString];
    
    NSURL *posterURL = [NSURL URLWithString:fullPosterURLString];
    NSURLRequest *posterRequest = [NSURLRequest requestWithURL:posterURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    cell.posterView.image = nil;
    __weak MovieCell *weakSelf = cell;
    [cell.posterView setImageWithURLRequest:posterRequest placeholderImage:nil
                             success:^(NSURLRequest *imageRequest, NSHTTPURLResponse *imageResponse, UIImage *image) {
                                 
                                 // imageResponse will be nil if the image is cached
                                 if (imageResponse) {
                                     //NSLog(@"Image was NOT cached, fade in image");
                                     weakSelf.posterView.alpha = 0.0;
                                     weakSelf.posterView.image = image;
                                     
                                     //Animate UIImageView back to alpha 1 over 0.3sec
                                     [UIView animateWithDuration:0.3 animations:^{
                                         weakSelf.posterView.alpha = 1.0;
                                     }];
                                 }
                                 else {
                                     //NSLog(@"Image was cached so just update the image");
                                     weakSelf.posterView.image = image;
                                 }
                             }
                             failure:^(NSURLRequest *request, NSHTTPURLResponse * response, NSError *error) {
                                 // do something for the failure condition
                             }];
    //    cell.textLabel.text = movies[@"title"];
    
    return cell;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    NSString *searchText = searchController.searchBar.text;
    if (searchText) {
        
        if (searchText.length != 0) {
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"title contains[cd] %@", searchText];
            self.filteredData = [self.movies filteredArrayUsingPredicate:pred];

        }
        else {
            self.filteredData = self.movies;
        }
        
        
    }
    [self.tableView reloadData];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    UITableViewCell *tappedCell = sender;
    NSLog(@"%@", sender);
    NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
    NSDictionary *movie = self.filteredData[indexPath.row];
    
    DetailsViewController *detailsViewController = [segue destinationViewController];
    detailsViewController.movie = movie;
    //NSLog(@"tapping on movie!");
}


@end
