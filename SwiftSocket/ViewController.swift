//
//  ViewController.swift
//  SwiftSocket
//
//  Created by dbl on 2020/3/7.
//  Copyright © 2020 dbl. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class ViewController: UIViewController {

    let host = "192.168.1.102"
    let port: UInt16 = 8080
    @IBOutlet weak var msgLabel: UILabel!
    
    var client: GCDAsyncSocket? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        
        client = GCDAsyncSocket.init(delegate: self as? GCDAsyncSocketDelegate, delegateQueue: DispatchQueue.main)
        
        //尝试连接
        do {
            try client?.connect(toHost: host, onPort: port)
        } catch let error {
            print(error)
        }
        
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        let message = "hellow Swift"
        
        /*
         tag: 消息标记
         withTimeout: 表示无限时长 ,永久不失效
         */
        client?.write(message.data(using: .utf8), withTimeout: -1, tag: 123)
    }
}

/// GCDAsyncSocketDelegate
extension ViewController: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("连接上了服务端 服务器IP：\(host) 断开：\(port)")
        client?.readData(withTimeout: -1, tag: 123)
        
        // 这里可以增加定时器 定时发送心跳包
    }
    
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        
        let recStr = String(data: data, encoding: .utf8)
        print(recStr!)
        msgLabel.text = recStr
        
        //读取到服务器数据后，需要再次获取 这个方法只是接受1次
        client?.readData(withTimeout: -1, tag: 123)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("发送数据 \(tag) \(String(describing: sock.connectedHost))")
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("断开连接\(err.debugDescription)")
        msgLabel.text = "断开连接"
        //监听到断开连接后 需要清空代理和socket
        client?.delegate = nil
        client = nil
        //这里可以增加重连的机制
    }
    
}

/*
 数据监听：
 使用的是YYNetwork
 或者使用mac命令终端输入 nc -lk 8080
 就可以互相发送数据监听接受了
 */

/*
 对于粘包的处理：
 发送方将数据包加上包头和包尾
 包头、包体以及包尾用字典形式包装成json字符串,接收方,通过解析获取json字符串中的包体
 便可进行进一步处理
 */
