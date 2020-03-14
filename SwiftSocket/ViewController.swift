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
    
    @IBOutlet weak var inputTextField: UITextField!
    var client: GCDAsyncSocket? = nil
    var timer: Timer! = nil
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
        /*
         tag: 消息标记
         withTimeout: 表示无限时长 ,永久不失效
         */
//        client?.write(message.data(using: .utf8), withTimeout: -1, tag: 123)
        sendData(inputTextField.text!.data(using: .utf8)! as NSData)
    }
}

/// GCDAsyncSocketDelegate
extension ViewController: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("连接上了服务端 服务器IP：\(host) 断开：\(port)")
        client?.readData(withTimeout: -1, tag: 123)
        // 定时发送心跳包 每隔5秒发送一次
        beginSendHeartData()
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
    }
    
}

extension ViewController {
    /// 发送数据 在数据包添加头部信息 为了解决TCP粘包问题
    func sendData(_ data: NSData) {
        let sendData: NSMutableData = NSMutableData()
        
        var dataLength = data.length
        
        let lengthData: Data = Data(bytes: &dataLength, count: dataLength)
        
        //使用4个字节存储长度信息 具体情况具体分析
        let range = Range.init(NSRange(location: 0, length: 4))
        let newLengthData = lengthData.subdata(in: range!)
        
        //然后拼接长度信息
        sendData.append(newLengthData)
        
        //拼接要发送的数据
        sendData.append(data as Data)
        print(sendData)
        //发送添加了长度信息的包
        client?.write(sendData as Data, withTimeout: -1, tag: 123)
    }
    
    /// 心跳包
    func beginSendHeartData() {
        timer = Timer(timeInterval: 30, target: self, selector: #selector(sendHeart), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    ///定时发送指令 这里瞎写的 和自己服务器协商吧
    @objc func sendHeart() {
        if timer != nil {
            var heart = "heart"
            let heartData = Data(bytes: &heart, count: heart.count)
            client?.write(heartData, withTimeout: -1, tag: 0)
        }
    }
}

/*
 数据监听：
 使用的是YYNetwork
 或者使用mac命令终端输入 nc -lk 8080
 就可以互相发送数据监听接受了
 */
