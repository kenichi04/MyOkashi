//
//  ViewController.swift
//  MyOkashi
//
//  Created by takashimakenichi on 2020/12/29.
//  Copyright © 2020 takashimakenichi. All rights reserved.
//

import UIKit
import SafariServices

class ViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, SFSafariViewControllerDelegate {
    
    @IBOutlet weak var searchText: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    /*
     Codableプロトコルを使用し、Jsonデータの項目（key）とプログラム内の変数名を同じにすることで（ex:name,makerなど）
     Jsonデータを変換した時に一括して変数にデータを格納することができる
     */
    // 取得したjsonを格納する構造体（お菓子の個別データ）
    struct ItemJson: Codable {
        // お菓子名称
        let name: String?
        // メーカー
        let maker: String?
        // 掲載URL
        let url: URL?
        // 画像URL
        let image: URL?
    }
    // ItemJson型の配列を管理する構造体
    struct ResultJson: Codable {
        // 複数要素
        let item: [ItemJson]?
    }
    
    // お菓子のリスト（タプル配列）
    var okashiList: [(name:String, maker:String, link:URL, image:URL)] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        searchText.delegate = self
        // プレースホルダー設定
        searchText.placeholder = "お菓子の名前を入力してください"
        
        // tableViewのdataSourceを設定
        tableView.dataSource = self
        // tableViewのdelegate設定
        tableView.delegate = self
    }
    
    // searchBar入力し、検索ボタンタップ時に呼ばれる
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // キーボードを閉じる
        view.endEditing(true)
        
        if let searchWord = searchBar.text {
            print(searchWord)
            // 入力されていたらお菓子を検索する
            searchOkashi(keyword: searchWord)
        }
    }
    
    // お菓子を検索する
    func searchOkashi(keyword: String) {
        // 入力したお菓子キーワードをURLエンコード,失敗するとnilが返るため、guard文をつかう
        guard let keyword_encode = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }
        // リクエストURLの組み立て、URL構造体を指定して変数に格納
        guard let req_url = URL(string:
            "https://sysbird.jp/toriko/api/?apikey=guest&format=json&keyword=\(keyword_encode)&max=10&order=r") else {
                return
        }
        print(req_url)
        
        //　URLからリクエストを管理するオブジェクトを生成
        let req = URLRequest(url: req_url)
        // データ転送を管理するためのセッションを生成
        // 第３引数ではdelegateやクロージャで使うキューを指定、今回はメインスレッドに対するキューを取得
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        // リクエストをタスクとして登録
        // タスク実行されると、クロージャーであるcopmpletionHandlerが実行される
        let task = session.dataTask(with: req, completionHandler: {
            // 以下には、取得後のデータ、通信状態の情報、失敗した時のエラー情報が格納されている
            (data, response, error) in
            // session終了
            session.finishTasksAndInvalidate()
            // do try catch エラーハンドリング
            do {
                // JsonDecoderインスタンス生成
                let decoder = JSONDecoder()
                // 取得したjsonデータ(変数data)をパース（解析）して格納, 宣言した構造体:ResultJsonのデータ構造に合わせる
                // Codablプロトコルを活用
                let json = try decoder.decode(ResultJson.self, from: data!)
//                print(json)
                
                // お菓子の情報が取得できているか確認
                // jsonはstruct宣言したResultJson型->プロパティitemにアクセス (ItemJson型の配列)
                if let items = json.item {
                    
                    // 再検索した時のために、お菓子リストを初期化(前回の結果をリフレッシュ)
                    self.okashiList.removeAll()
                    
                    // 取得しているお菓子情報の数だけ処理
                    for item in items {
                        // ItemJsonインスタンスの各プロパティにアクセス
                        if let name = item.name, let maker = item.maker, let link = item.url, let image = item.image {
                            // 一つのお菓子情報をタプルでまとめて管理
                            let okashi = (name, maker, link, image)
                            // 配列に追加
                            self.okashiList.append(okashi)
                        }
                    }
                    
                    // tableViewを更新する（前回の結果をリフレッシュ）
                    self.tableView.reloadData()
                    
                    // デバッグ用
                    if let okashidbg = self.okashiList.first {
                        print("---------------------------")
                        print(okashidbg)
                    }
                }
                
            } catch {
                // エラー処理
                print(error)
            }
        })
        // dataTaskで登録されたリクエストのタスクを実行->completionHandler以下に移行する
        task.resume()
        
    }
    
    // UITableViewDatasource関連/cellの総数を返す
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return okashiList.count
    }
    
    // UITableViewDatasource関連/cellの値を返す
    // セル（行）設定時に毎回実行される、indexPathに設定したいセルの位置情報が渡される
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 表示するcellオブジェクト（一行）を生成、設定したセルIDを渡す
        let cell = tableView.dequeueReusableCell(withIdentifier: "okashiCell", for: indexPath)
        // お菓子のタイトル設定
        cell.textLabel?.text = okashiList[indexPath.row].name
        // お菓子画像を取得（画像URLから画像本体を取得する）、エラーの場合はnilが返る
        if let imageData = try? Data(contentsOf: okashiList[indexPath.row].image) {
            // UIImageで画像オブジェクトを生成し、cellに設定
            cell.imageView?.image = UIImage(data: imageData)
        }
        return cell
    }
    
    // UITableVIewDelegate関連/cell選択時に呼ばれる
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // ハイライト解除
        tableView.deselectRow(at: indexPath, animated: true)
        
        // urlを渡して、SFSafariViewControllerインスタンス生成
        let safariViewController = SFSafariViewController(url: okashiList[indexPath.row].link)
        // delegate設定
        safariViewController.delegate = self
        // safariView表示
        present(safariViewController, animated: true, completion: nil)
    }
    
    // SafariViewが閉じた時に呼ばれるdelegateメソッド
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        // safariViewを閉じる
        dismiss(animated: true, completion: nil)
    }
    

}

