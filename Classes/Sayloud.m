//
//  Sayloud.m
//  MWFeedParser
//
//  Created by md11235 Zhang on 1/10/13.
//  Copyright (c) 2013 Michael Waterfall. All rights reserved.
//

#import "Sayloud.h"

@implementation Sayloud

- (id) init {
    if((self = [super init])) {
        receivedData = [[NSMutableData alloc] init];
        mp3URLList = [[NSMutableArray alloc] init];
        
        isLocation = NO;
    }
    
    return self;
}

- (void) readText:(NSString *) textContent {
    // get ready for this new textContent
    [mp3URLList removeAllObjects];
    
    [textContent retain];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[NSURL
                                                 URLWithString:@"http://lh.sayloud.com/tts.py"]];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"text/plain; charset=UTF-8"
   forHTTPHeaderField:@"Content-Type"];
    
    [request setValue:[NSString stringWithFormat:@"%d", [textContent length]]
   forHTTPHeaderField:@"Content-Length"];
    
    [request setHTTPBody:[textContent dataUsingEncoding:NSUTF8StringEncoding]];
    
    [[NSURLConnection alloc]
     initWithRequest:request
     delegate:self];
    
    [textContent release];
    NSLog(@"begin to request sayloud\n");
}

- (void) stop {
    
}

#pragma mark -
#pragma mark NSURLConnection

/*
 this method might be calling more than one times according to incoming data size
 */
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [receivedData appendData:data];
}
/*
 if there is an error occured, this method will be called by connection
 */
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    
    NSLog(@"%@" , error);
}

/*
 if data is successfully received, this method will be called by connection
 */
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    //initialize convert the received data to string with UTF8 encoding
    NSString * mp3PlaylistURL = [[NSString alloc] initWithData:receivedData
                                                      encoding:NSASCIIStringEncoding];
    
    NSCharacterSet  * whitespaces = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    mp3PlaylistURL = [mp3PlaylistURL stringByTrimmingCharactersInSet:whitespaces];
    
    NSLog(@"playlist URL is %@" , mp3PlaylistURL);
    
    //NSXMLParser * parser = [[NSXMLParser alloc] initWithContentsOfURL: [NSURL URLWithString:@"http://192.168.1.100:8080/test.xml"]];
    //NSXMLParser * parser = [[NSXMLParser alloc] initWithContentsOfURL: [NSURL URLWithString:@"http://lh.sayloud.com/c/2ec90a88a59321b99e038fb8d361949f.vmcpw.xml"]];
    //NSXMLParser * parser = [[NSXMLParser alloc] initWithData:[xmlData dataUsingEncoding:NSUTF8StringEncoding]];
    NSURL * url = [NSURL URLWithString:[mp3PlaylistURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSLog(@"NSURL IS %@", url);
    
    parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    
    [parser setDelegate:self];
    
    [parser setShouldProcessNamespaces:YES];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:YES];
    
    Boolean success = [parser parse];
    
    NSLog(@"parse result: %d", success);
    
    if(NO == success) {
        NSLog(@"error: %@", [parser parserError]);
        NSLog(@"line: %d", [parser lineNumber]);
        NSLog(@"col : %d", [parser columnNumber]);
    }
    
    [mp3PlaylistURL release];
    [parser release];
    
    [receivedData setLength:0];
}

#pragma mark -
#pragma mark MP3 playlist parsing using NSXMLParser

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
    isLocation = [elementName isEqualToString:@"location"];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if(isLocation) {
        NSLog(@"found a URL: %@", string);
        [mp3URLList addObject:string];
        
        isLocation = NO;
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"parsing error: %@", parseError);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    [self playMP3WithURL];
}

#pragma mark - 
#pragma mark Play MP3

- (void) playMP3WithURL {
    NSString * url;
    if([mp3URLList count] > 0) {
        url = [[mp3URLList objectAtIndex:0] retain];
        [mp3URLList removeObjectAtIndex:0];
    } else {
        return;
    }
    
    NSLog(@"reading URL: %@", url);
    
    NSCharacterSet  * whitespaces = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    url = [url stringByTrimmingCharactersInSet:whitespaces];
    
    NSError * error;
    NSURL * aURL = [NSURL URLWithString:url];
    
    NSData * soundData = [NSData dataWithContentsOfURL:aURL];
    
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:[aURL lastPathComponent]] URLByAppendingPathExtension:@"mp3"];
    NSString * filePath = [fileURL path];
    
    NSLog(@"file temp path:%@", filePath);
    
    [soundData writeToFile:filePath atomically:YES];
    
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    
    if(nil == audioPlayer) {
        NSLog(@"AudioPlayer init error %@", [error description]);
    } else {
        [audioPlayer setDelegate:self];
        [audioPlayer play];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [player release];
    
    [self playMP3WithURL];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"AVAudioPlayer Error:%@", [error description]);
}

#pragma mark -
#pragma mark Memory Management

- (void) dealloc {
    [receivedData release];
    [mp3URLList release];
    [super dealloc];
}

@end
