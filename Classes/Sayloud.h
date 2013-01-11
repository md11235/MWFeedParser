//
//  Sayloud.h
//  MWFeedParser
//
//  Created by md11235 Zhang on 1/10/13.
//  Copyright (c) 2013 Michael Waterfall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface Sayloud : NSObject <NSXMLParserDelegate, AVAudioPlayerDelegate> {
    NSMutableData * receivedData;
    NSXMLParser * parser;
    
    BOOL isLocation;
    NSMutableArray * mp3URLList;
    
    AVAudioPlayer * audioPlayer;
}

- (void) readText:(NSString *) textContent;
- (void) stop;

@end
