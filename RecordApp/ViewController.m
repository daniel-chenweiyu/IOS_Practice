//
//  ViewController.m
//  RecordApp
//
//  Created by Daniel on 2016/12/5.
//  Copyright © 2016年 Daniel. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVAudioRecorderDelegate,AVAudioPlayerDelegate,UITableViewDelegate, UITableViewDataSource>
{
    NSMutableDictionary * recordSetting ;
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
    NSArray * directoryContent ;
    NSFileManager * fileManager;
    NSString * directory;
    NSTimer * timer ;
    NSTimeInterval currentTime;
    NSTimeInterval totalTime;
    int count ;
}
@property (weak, nonatomic) IBOutlet UILabel *timeCount;
@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *recordPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    count = 0 ;
    // Do any additional setup after loading the view, typically from a nib.
    [_stopButton setEnabled:NO];
    [_playButton setEnabled:NO];
    //設定錄音檔格式
    recordSetting =[NSMutableDictionary dictionaryWithCapacity:0];
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatAppleIMA4] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:22050.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    [recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    //設定Audio Session Category
    AVAudioSession * session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    //取路徑
    directory = [NSString stringWithFormat:@"%@/Documents/",NSHomeDirectory()];
    //    directory = [NSString stringWithFormat:@"%@",[[NSFileManager defaultManager]URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject];
    //        NSURL * cacheURL = [[NSFileManager defaultManager]URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;
    fileManager = [NSFileManager defaultManager];
    directoryContent = [fileManager contentsOfDirectoryAtPath:directory error:NULL];
    //    directoryContent = [fileManager contentsOfDirectoryAtURL:cacheURL includingPropertiesForKeys:@"*.caf" options:nil error:NULL];
    
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return directoryContent.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text = directoryContent[indexPath.row];
    //顯示整個時間的秒數
    NSString * fullFilePathName = [NSString stringWithFormat:@"%@%@",directory,directoryContent[indexPath.row]];
    NSURL * fileURL = [NSURL fileURLWithPath:fullFilePathName];
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
    totalTime = player.duration;
    cell.detailTextLabel.text =[NSString stringWithFormat:@"%.0f秒",totalTime];
    
    
    return cell;
}
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    //delete
    if(editingStyle == UITableViewCellEditingStyleDelete){
        NSString * fullFilePathName = [NSString stringWithFormat:@"%@%@",directory,directoryContent[indexPath.row]];
        [fileManager removeItemAtPath:fullFilePathName error:nil];
        directoryContent = [fileManager contentsOfDirectoryAtPath:directory error:NULL];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!recorder.recording){
        NSString * fullFilePathName = [NSString stringWithFormat:@"%@%@",directory,directoryContent[indexPath.row]];
        NSURL * fileURL = [NSURL fileURLWithPath:fullFilePathName];
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
        [player play];
    }
    
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)recordPauseTapped:(UIButton *)sender {
    if(count == 0){
        //現在時間
        NSDate *now = [NSDate date];
        //timer觸發
        timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd HH-mm-ss";
        [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        NSDate * currentDate =[dateFormatter stringFromDate:now];
        NSString * currentTime = [NSString stringWithFormat:@"%@.caf",currentDate];
        //準備錄音檔存放路徑
        NSString * recorderFilePath = [NSString stringWithFormat:@"%@%@",directory,currentTime];
        NSURL * url = [NSURL fileURLWithPath:recorderFilePath];
        //建立AVAudioRecorder元件
        recorder =[[AVAudioRecorder alloc]initWithURL:url settings:recordSetting error:nil];
        [recorder prepareToRecord];
        count++;
    }
    
    // Stop the audio player before recording
    if (player.playing) {
        [player stop];
    }
    
    if (!recorder.recording) {
        
        // Start recording
        [recorder record];
        [_recordPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
        
    } else {
        
        // Pause recording
        [recorder pause];
        [_recordPauseButton setTitle:@"Record" forState:UIControlStateNormal];
    }
    
    [_stopButton setEnabled:YES];
    [_playButton setEnabled:NO];
}
- (IBAction)stopTapped:(UIButton *)sender {
    [recorder stop];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:nil];
    [_recordPauseButton setTitle:@"Record" forState:UIControlStateNormal];
    
    [_stopButton setEnabled:NO];
    [_playButton setEnabled:YES];
    count = 0 ;
    [timer invalidate];
    _timeCount.text = @"00:00:00";
    //更新矩陣
    directoryContent = [fileManager contentsOfDirectoryAtPath:directory error:NULL];
    [ self.myTableView reloadData] ;
}


- (IBAction)playTapped:(UIButton *)sender {
    if (!recorder.recording){
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:recorder.url error:nil];
        [player play];
    }
}
-(void)updateTime:(NSTimer *)timer
{
    currentTime = recorder.currentTime;
    NSInteger tempHour = currentTime / 3600;
    NSInteger tempMinute = currentTime / 60 - (tempHour * 60);
    NSInteger tempSecond = currentTime - (tempHour * 3600 + tempMinute * 60);
    
    NSString *hour = [[NSNumber numberWithInteger:tempHour] stringValue];
    NSString *minute = [[NSNumber numberWithInteger:tempMinute] stringValue];
    NSString *second = [[NSNumber numberWithInteger:tempSecond] stringValue];
    if (tempHour < 10) {
        hour = [@"0" stringByAppendingString:hour];
    }
    if (tempMinute < 10) {
        minute = [@"0" stringByAppendingString:minute];
    }
    if (tempSecond < 10) {
        second = [@"0" stringByAppendingString:second];
    }
    self.timeCount.text = [NSString stringWithFormat:@"%@:%@:%@", hour, minute, second];

}

@end
