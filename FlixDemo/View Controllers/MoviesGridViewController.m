//
//  MoviesGridViewController.m
//  FlixDemo
//
//  Created by jordan487 on 6/26/19.
//  Copyright © 2019 jordan487. All rights reserved.
//

#import "MoviesGridViewController.h"
#import "MovieCollectionCell.h"
#import "UIImageView+AFNetworking.h"
#import "DetailsViewController.h"

@interface MoviesGridViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UISearchResultsUpdating>

@property (nonatomic, strong) NSArray *movies;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) UISearchController *searchController;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBarPlaceholder;
@property (strong, nonatomic) NSArray *filteredData;


@end

@implementation MoviesGridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [self fetchMovies];
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *) self.collectionView.collectionViewLayout;
    
    layout.minimumInteritemSpacing = 5;
    layout.minimumLineSpacing = 5;
    CGFloat postersPerLine = 2;
    CGFloat itemWidth = (self.collectionView.frame.size.width - layout.minimumLineSpacing * (postersPerLine - 1)) / postersPerLine;
    CGFloat itemHeight = 1.5 * itemWidth;
    layout.itemSize = CGSizeMake(itemWidth, itemHeight);
    
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
    [self.searchBarPlaceholder addSubview: self.searchController.searchBar];
    
    self.collectionView.contentInsetAdjustmentBehavior = NO;
    self.definesPresentationContext = YES;
}

- (void) fetchMovies {
    // Do any additional setup after loading the view.
    
    NSURL *url = [NSURL URLWithString:@"https://api.themoviedb.org/3/movie/now_playing?api_key=a07e22bc18f5cb106bfe4cc1f83ad8ed"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            NSLog(@"%@", [error localizedDescription]);
        }
        else {
            NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                        
            self.movies = dataDictionary[@"results"];
            self.filteredData = self.movies;
        }
        [self.collectionView reloadData];
    }];
    [task resume];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     // Get the new view controller using [segue destinationViewController].
     // Pass the selected object to the new view controller.
     UICollectionViewCell *tappedCell = sender;
     NSIndexPath *indexPath = [self.collectionView indexPathForCell:tappedCell];
     NSDictionary *movie = self.filteredData[indexPath.row];
 
     DetailsViewController *detailsViewController = [segue destinationViewController];
     detailsViewController.movie = movie;
     //NSLog(@"tapping on movie!");
}


- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    MovieCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MovieCollectionCell" forIndexPath:indexPath];
    
    NSDictionary *movie = self.filteredData[indexPath.item];
    NSString *baseURLString = @"https://image.tmdb.org/t/p/w500";
    NSString *posterURLString = movie[@"poster_path"];
    NSString *fullPosterURLString = [baseURLString stringByAppendingString:posterURLString];
    
    NSURL *posterURL = [NSURL URLWithString:fullPosterURLString];
    cell.posterView.image = nil;
    [cell.posterView setImageWithURL:posterURL];
    
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.filteredData.count;
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
    [self.collectionView reloadData];
}

@end
