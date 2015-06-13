//
//  SmileSettingVC.m
//  TouchID
//
//  Created by ryu-ushin on 5/25/15.
//  Copyright (c) 2015 rain. All rights reserved.
//

#import "SmileSettingVC.h"
#import "SmileAuthenticator.h"
#import "SmilePasswordContainerView.h"

@interface SmileSettingVC () <UITextFieldDelegate, SmileContainerLayoutDelegate>

@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UIButton *touchIDButton;
@property (weak, nonatomic) IBOutlet SmilePasswordContainerView *passwordView;
@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;

@end

@implementation SmileSettingVC{
    BOOL _needTouchID;
    NSInteger _inputCount;
    NSString *_bufferPassword;
    NSString *_newPassword;
    NSInteger _passLength;
    NSInteger _failCount;
}

#pragma mark - SmileContainerLayoutDelegate
-(void)smileContainerLayoutSubview{
    self.passwordView.smilePasswordView.dotCount = self.passwordField.text.length;
}

- (IBAction)dismissSelf:(id)sender {
    
    [[SmileAuthenticator sharedInstance] authViewControllerDismissed];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)useTouchID:(id)sender {
    [[SmileAuthenticator sharedInstance] authenticateWithSuccess:^{
        [[SmileAuthenticator sharedInstance] touchID_OR_PasswordAuthSuccess];
        self.passwordView.smilePasswordView.dotCount = [SmileAuthenticator sharedInstance].passcodeDigit;
        [self performSelector:@selector(dismissSelf:) withObject:nil afterDelay:0.15];
    } andFailure:^(LAError errorCode) {
        self.descLabel.hidden = NO;
        if (errorCode == LAErrorUserFallback || errorCode == LAErrorUserCancel) {
            [self.passwordField becomeFirstResponder];
        }
    }];

}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (_needTouchID) {
        [self useTouchID:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([SmileAuthenticator sharedInstance].navibarTranslucent) {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        [self.navigationController.navigationBar setShadowImage:[UIImage new]];
        [self.navigationController.navigationBar setTranslucent:YES];
    }
    
    if ([SmileAuthenticator sharedInstance].nightMode) {
        [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
        [self.passwordField setKeyboardAppearance:UIKeyboardAppearanceDark];
        self.view.backgroundColor = [UIColor blackColor];
        self.descLabel.textColor = [UIColor whiteColor];
    }
    
    if ([SmileAuthenticator sharedInstance].descriptionTextColor) {
        self.descLabel.textColor = [SmileAuthenticator sharedInstance].descriptionTextColor;
    }

    if ([SmileAuthenticator sharedInstance].backgroundImage) {
        self.bgImageView.image = [SmileAuthenticator sharedInstance].backgroundImage;
    }
    
    self.passwordView.delegate = self;
    
    //for tint color
    if ([SmileAuthenticator sharedInstance].tintColor) {
        self.navigationController.navigationBar.tintColor = [SmileAuthenticator sharedInstance].tintColor;
    }
    
    //for touchid image
    UIImage *iconImage = [UIImage imageNamed:[SmileAuthenticator sharedInstance].touchIDIconName];
    [self.touchIDButton setImage:iconImage forState:UIControlStateNormal];
    
    self.descLabel.text = [NSString stringWithFormat:NSLocalizedString(@"SMILE_INPUT_DESCRIPTION", nil), (long)[SmileAuthenticator sharedInstance].passcodeDigit];
    
    switch ([SmileAuthenticator sharedInstance].securityType) {
        case INPUT_ONCE:
            
            self.navigationItem.title = NSLocalizedString(@"SMILE_INPUT_ONCE_TITLE", nil);
            
            break;
            
        case INPUT_TWICE:
            
            self.navigationItem.title = NSLocalizedString(@"SMILE_INPUT_TWICE_TITLE", nil);
            
            break;
            
        case INPUT_THREE:
            
            self.navigationItem.title = NSLocalizedString(@"SMILE_INPUT_THREE_TITLE", nil);
            self.descLabel.text = [NSString stringWithFormat:NSLocalizedString(@"SMILE_INPUT_THREE_STEP_2", nil), (long)[SmileAuthenticator sharedInstance].passcodeDigit];
            
            break;
            
        case INPUT_TOUCHID:
            
            self.touchIDButton.hidden = NO;
            
            if (![SmileAuthenticator sharedInstance].appLogoName.length) {
                self.navigationItem.title = NSLocalizedString(@"SMILE_INPUT_TOUCHID_TITLE", nil);
            } else {
                self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[SmileAuthenticator sharedInstance].appLogoName]];
            }
            
            break;
            
        default:
            break;
    }
    
    //hide bar button
    if ([SmileAuthenticator sharedInstance].securityType == INPUT_TOUCHID) {
        if (self.navigationItem.rightBarButtonItem) {
            [self.navigationItem.rightBarButtonItem setTintColor:[UIColor clearColor]];
            [self.navigationItem.rightBarButtonItem setEnabled:NO];
        }
        
        //begin check canAuthenticate
        NSError *error = nil;
        if ([SmileAuthenticator canAuthenticateWithError:&error]) {
            _needTouchID = YES;
        } else {
            self.touchIDButton.hidden = YES;
            [self.passwordField becomeFirstResponder];
        }
        
    } else {
        [self.passwordField becomeFirstResponder];
    }
    
    self.passwordField.delegate = self;
    [self.passwordField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    _passLength =[SmileAuthenticator sharedInstance].passcodeDigit;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - handle user input
-(void)clearText {
    self.passwordField.text = @"";
    self.passwordView.smilePasswordView.dotCount = 0;
}

-(void)passwordInputComplete{
    [[SmileAuthenticator sharedInstance] userSetPassword: _newPassword];
    [self dismissSelf:nil];
}

-(void)passwordCancleComplete{
    [SmileAuthenticator clearPassword];
    [self dismissSelf:nil];
}

-(void)passwordWrong{
    _inputCount = 0;
    
    [self clearText];
    
    _failCount++;
    
    [self.passwordView.smilePasswordView shakeAnimation];
    
    [[SmileAuthenticator sharedInstance] touchID_OR_PasswordAuthFail:_failCount];
    
    self.descLabel.text = [NSString stringWithFormat:NSLocalizedString(@"SMILE_INPUT_FAILED", nil), (long)_failCount];
}

-(void)passwordNotMatch{
    
    _inputCount = _inputCount -2;
    
    [self clearText];
    [self.passwordView.smilePasswordView shakeAnimation];
    
    self.descLabel.text = NSLocalizedString(@"SMILE_INPUT_NOT_MATCH", nil);
}

-(void)reEnterPassword{
    _bufferPassword = _newPassword;
    [self clearText];
    
    [self.passwordView.smilePasswordView slideToLeftAnimation];
    
    self.descLabel.text = [NSString stringWithFormat:NSLocalizedString(@"SMILE_INPUT_RE-ENTER", nil), (long)[SmileAuthenticator sharedInstance].passcodeDigit];
}

-(void)enterNewPassword{
    [self clearText];
    
    [self.passwordView.smilePasswordView slideToLeftAnimation];
    
    self.descLabel.text = [NSString stringWithFormat:NSLocalizedString(@"SMILE_INPUT_THREE_STEP_1", nil), (long)[SmileAuthenticator sharedInstance].passcodeDigit];
}

-(void)handleINPUT_TOUCHID{
    if ([SmileAuthenticator isSamePassword:_newPassword]) {
        [[SmileAuthenticator sharedInstance] touchID_OR_PasswordAuthSuccess];
        [self passwordInputComplete];
    } else {
        [self passwordWrong];
    }
}

-(void)handleINPUT_ONCE{
    if ([SmileAuthenticator isSamePassword:_newPassword]) {
        [self passwordCancleComplete];
    } else {
        [self passwordWrong];
    }
}

-(void)handleINPUT_TWICE{
    if (_inputCount == 1) {
        [self reEnterPassword];
    } else if (_inputCount == 2) {
        if ([_bufferPassword isEqualToString:_newPassword]) {
            [self passwordInputComplete];
        } else {
            [self passwordNotMatch];
        }
    }
}

-(void)handleINPUT_THREE{
    if (_inputCount == 1) {
        if ([SmileAuthenticator isSamePassword:_newPassword]) {
            [self enterNewPassword];
        } else {
            [self passwordWrong];
        }
    } else if (_inputCount == 2) {
        [self reEnterPassword];
    } else if (_inputCount == 3) {
        if ([_bufferPassword isEqualToString:_newPassword]) {
            [self passwordInputComplete];
        } else {
            [self passwordNotMatch];
        }
    }
}

-(void)handleUserInput{
    switch ([SmileAuthenticator sharedInstance].securityType) {
        case INPUT_ONCE:
            
            [self handleINPUT_ONCE];
            
            break;
            
        case INPUT_TWICE:
            
            _inputCount++;
            
            [self handleINPUT_TWICE];
            
            break;
            
        case INPUT_THREE:
            
            _inputCount++;
            
            [self handleINPUT_THREE];
            
            break;
            
        case INPUT_TOUCHID:
            
            [self handleINPUT_TOUCHID];
            
            break;
            
        default:
            break;
    }

}

#pragma mark - UITextFieldDelegate

-(void)textFieldDidChange:(UITextField*)textField{
    
    self.passwordView.smilePasswordView.dotCount = textField.text.length;
    
    if (textField.text.length == _passLength) {
        
        _newPassword = textField.text;
        
        [self performSelector:@selector(handleUserInput) withObject:nil afterDelay:0.3];
    }
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    if (textField.text.length >= _passLength) {
        return NO;
    }
    
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
