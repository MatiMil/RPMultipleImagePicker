//
//  MultipleImagePickerViewController.m
//
//  Created by Renato Peterman on 17/08/14.
//  Copyright (c) 2014 Renato Peterman. All rights reserved.
//

#import "RPMultipleImagePickerViewController.h"

@interface RPMultipleImagePickerViewController ()

@property (strong, nonatomic) NSIndexPath *selectedIndexPathFromDragAndDrop;

@end

@implementation RPMultipleImagePickerViewController

- (instancetype)init
{
    self = [super initWithNibName:@"RPMultipleImagePicker" bundle:[NSBundle mainBundle]];
    if (self) {
        self.sourceType = UIImagePickerControllerSourceTypeCamera; // Default
        self.images = [NSMutableArray new];
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // UI Updates always in Main Thread
    dispatch_async(dispatch_get_main_queue(), ^{
        // Refresh
        [self setCurrentImage:self.image];
        [self reloadCollectionView];
        [self refreshTitle];
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [self selectLastImage];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                               initWithTarget:self
                                               action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 0.5;
    [self.collectionView addGestureRecognizer:longPress];
    
    // Style
    self.navigationController.navigationBar.barStyle = _useDefaultDesign ? UIBarStyleDefault : UIBarStyleBlack;
    
    // Background
    self.view.backgroundColor = _useDefaultDesign ? [UIColor whiteColor] : [UIColor darkGrayColor];
    
    [self.collectionView registerClass:[RPImageCell class] forCellWithReuseIdentifier:@"RPImageCell"];
    
    self.selectedIndex = 0;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.bgView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor lightGrayColor] CGColor], (id)[[UIColor darkGrayColor] CGColor], nil];
    [self.bgView.layer insertSublayer:gradient atIndex:0];
    
    // Background view for images collection
    self.bgView.layer.shadowColor = _useDefaultDesign ? [UIColor lightGrayColor].CGColor : [UIColor blackColor].CGColor;
    self.bgView.layer.shadowRadius = 3.0f;
    
    // Customize default ImageView
    self.imageView.layer.masksToBounds = true;
    self.imageView.layer.shadowColor = _useDefaultDesign ? [UIColor lightGrayColor].CGColor : [UIColor blackColor].CGColor;
    self.imageView.layer.shadowOpacity = 0.3f;
    self.imageView.layer.shadowRadius = 6.0f;
    
    // Picker Controller Init
    self.pickerController = [[UIImagePickerController alloc] init];
    self.pickerController.delegate = self;
    self.pickerController.sourceType = self.sourceType;
    
    // Bt Remover
    self.btRemover.backgroundColor = [UIColor whiteColor];
    self.btRemover.layer.cornerRadius = self.btRemover.frame.size.height / 2;
    
    if (_useDefaultDesign) {
        // Remover Button
        self.btRemover.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.btRemover.layer.borderWidth = 1.0f;
        
        // CollectionView Design
        self.collectionView.backgroundColor = [UIColor lightGrayColor];
    }
    
    // Set buttons to navigation
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Done") style:UIBarButtonItemStyleDone target:self action:@selector(done)];

    // iOS 7 only
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        doneButton.tintColor = _useDefaultDesign ? self.view.tintColor : [UIColor yellowColor];
    }
    
    [self.navigationItem setLeftBarButtonItem:cancelButton];
    [self.navigationItem setRightBarButtonItem:doneButton];
    
    self.navigationController.navigationBarHidden = NO;
    
    // Set ImageView size
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){ // iPhone
        
        if([[UIScreen mainScreen] bounds].size.height > 500){
            self.imageView.bounds = CGRectMake(self.imageView.bounds.origin.x, self.imageView.bounds.origin.y, 240, 350);
        }else{
            self.imageView.bounds = CGRectMake(self.imageView.bounds.origin.x, self.imageView.bounds.origin.y, 190, 300);
        }
        
    }else{
        // TODO: iPad
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-  (void)handleLongPress:(UILongPressGestureRecognizer*)sender {
    
    CGPoint selectedPoint = [sender locationInView:self.collectionView];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            
            self.selectedIndexPathFromDragAndDrop = [self.collectionView indexPathForItemAtPoint:selectedPoint];
            
            // Only if there are more than 2 images (whatsapp like behaviour)
            if (self.selectedIndexPathFromDragAndDrop.row != 0 && self.images.count > 1) {
                [self.collectionView beginInteractiveMovementForItemAtIndexPath:self.selectedIndexPathFromDragAndDrop];
            }
            
            break;
        case UIGestureRecognizerStateChanged:
            // Only if there are more than 1 image (whatsapp like behaviour)
            if (self.selectedIndexPathFromDragAndDrop.row != 0 && selectedPoint.y > 0.0f && self.images.count > 1) {
                [self.collectionView updateInteractiveMovementTargetPosition:selectedPoint];
            }
            else if (self.images.count > 1) {
                [self.collectionView endInteractiveMovement];
                
                // Disable Gesture for deleting and refreshing tables
                sender.enabled = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.images removeObjectAtIndex:self.selectedIndexPathFromDragAndDrop.row - 1];
                    [self reloadCollectionView];
                    [self selectLastImage];
                    // Set Last Image to big picture
                    [self setCurrentImage:self.images[self.selectedIndex - 1]];
                    [self refreshTitle];
                });
            }
            
            // Enable Gesture Recognizer after disabling it for furter usage
            sender.enabled = YES;
            break;
        case UIGestureRecognizerStateEnded:
            [self.collectionView endInteractiveMovement];
            break;
        default:
            [self.collectionView cancelInteractiveMovement];
            break;
    }

    

}

#pragma mark - Util

- (void) addImage:(UIImage *)image
{
    self.image = image;
    [self.images addObject:image];
}

- (void) selectLastImage
{
    if(self.images.count > 0){
        self.selectedIndex = self.images.count;
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionRight];
    }else{
        self.selectedIndex = 0;
    }
}

- (void) setCurrentImage:(UIImage *) image {
    
    self.imageView.image = image;
    double heigth = self.imageView.image.size.height * self.imageView.bounds.size.width / self.imageView.image.size.width;
    self.imageView.bounds = CGRectMake(self.imageView.bounds.origin.x, self.imageView.bounds.origin.y, self.imageView.bounds.size.width, heigth);
    
    // Positioning button x
    double btX = (self.imageView.center.x - (self.imageView.bounds.size.width/2)) - 15;
    double btY = (self.imageView.center.y - (self.imageView.bounds.size.height/2)) - 15;
    self.btRemover.frame = CGRectMake(btX, btY, self.btRemover.bounds.size.width, self.btRemover.bounds.size.height);
    
}

- (void) refreshTitle
{
    if(self.images.count == 1){
        self.title = [NSString stringWithFormat:@"1 %@", NSLocalizedString(@"image", @"image")];
    }else if(self.images.count > 1){
        self.title = [NSString stringWithFormat:@"%d %@", self.images.count, NSLocalizedString(@"images", @"images")];
    }
}

- (void) done
{
    
    if(self.doneCallback){
        self.doneCallback(self.images);
    }
    
    UIViewController *viewControllerToPopTo = self.navigationController.childViewControllers[1] ? self.navigationController.childViewControllers[1] : self.navigationController.childViewControllers[0];
    
    [self.navigationController popToViewController:viewControllerToPopTo animated:YES];
}

- (void) cancel
{
    self.image = nil;
    self.images = nil;
    
    UIViewController *viewControllerToPopTo = self.navigationController.childViewControllers[1] ? self.navigationController.childViewControllers[1] : self.navigationController.childViewControllers[0];
    
    [self.navigationController popToViewController:viewControllerToPopTo animated:YES];
}

- (void) reloadCollectionView
{
    [self.collectionView performBatchUpdates:^{
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    } completion:nil];
}

#pragma mark - Collection view delegate

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {

    return indexPath.row != 0;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    
    UIImage *tempImage = self.images[sourceIndexPath.row - 1];
    self.images[sourceIndexPath.row - 1] = self.images[destinationIndexPath.row - 1];
    self.images[destinationIndexPath.row - 1] = tempImage;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.images.count + 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"RPImageCell";
    RPImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    if(cell == nil){
        cell = [[RPImageCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 50.0f)];
    }
    
    if(indexPath.row == 0){
        [cell styleAddButton];
        cell.backgroundImageView.image = nil;
    }else{
        [cell styleImage];
        cell.backgroundImageView.image = [self.images objectAtIndex:(indexPath.row-1)];
    }

    return cell;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(50, 50);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0){
        
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        if (self.customPickerController != nil) {
            [self presentViewController:self.customPickerController animated:YES completion:nil];
        }
        else {
            [self presentViewController: self.pickerController animated:YES completion:nil];
        }
        
    }else{
        
        [self setCurrentImage:[self.images objectAtIndex:(indexPath.row-1)]];
        self.selectedIndex = indexPath.row;
        
    }
}

#pragma mark - ImagePicker delegate methods

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    UIImage *originalImage, *editedImage, *imageToUse;
    
    if (CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
        
        if(self.images == nil){
            self.images = [NSMutableArray new];
        }
        
        editedImage = (UIImage *) [info objectForKey: UIImagePickerControllerEditedImage]; // Edited image if available
        originalImage = (UIImage *) [info objectForKey: UIImagePickerControllerOriginalImage];
        imageToUse = editedImage ? editedImage : originalImage;
        
        [self addImage:imageToUse];
        [picker dismissViewControllerAnimated:YES completion:nil];
        
    }
}

#pragma mark - UI navigation bar delegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    
    navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
}

#pragma mark - IBActions

-(IBAction)remove:(id)sender
{
    [self.images removeObjectAtIndex:(self.selectedIndex-1)];
    [self reloadCollectionView];
    [self selectLastImage];
    
    if(self.images.count > 0){
        [self setCurrentImage:[self.images objectAtIndex:(self.selectedIndex-1)]];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self refreshTitle];
}

@end
