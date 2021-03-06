//
//  JSGroupInfoViewController.swift
//  Chming_iOS
//
//  Created by leejaesung on 2017. 8. 1..
//  Copyright © 2017년 leejaesung. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import Alamofire
import SwiftyJSON
import Toaster

class JSGroupInfoViewController: UIViewController, IndicatorInfoProvider, UITableViewDelegate, UITableViewDataSource {
    
    var groupPK:Int?
    var groupInfo: JSGroupInfo? // 모임 정보 뷰에서 사용되는 데이터 묶음입니다. (공지사항 데이터 제외)
    var noticeList: [JSGroupBoard]? // 모임 정보 뷰에서 보이는 공지사항을 보여주기 위한 객체입니다.
    
    @IBOutlet var buttonGroupJoinOutlet: UIButton!
    @IBOutlet var buttonGroupFavoriteOutlet: UIButton!
    @IBOutlet var mainTableView:UITableView!
    
    
    
    /*******************************************/
    // MARK: -  Life Cycle                     //
    /*******************************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 모임 정보 뷰는 테이블뷰로 이루어져 있습니다.
        mainTableView.delegate = self
        mainTableView.dataSource = self
        
        buttonGroupFavoriteOutlet.applyGradient(withColours: [#colorLiteral(red: 1, green: 0.3094263673, blue: 0.4742257595, alpha: 1),#colorLiteral(red: 1, green: 0.667937696, blue: 0.4736554623, alpha: 1)], gradientOrientation: .horizontal)
        buttonGroupJoinOutlet.applyGradient(withColours: [#colorLiteral(red: 1, green: 0.667937696, blue: 0.4736554623, alpha: 1),#colorLiteral(red: 1, green: 0.3094263673, blue: 0.4742257595, alpha: 1)], gradientOrientation: .horizontal)
        
        buttonGroupJoinOutlet.roundedButton(corners: [.topLeft, .bottomLeft], radius: buttonGroupJoinOutlet.frame.height / 2)
        buttonGroupFavoriteOutlet.roundedButton(corners: [.topRight, .bottomRight], radius: buttonGroupFavoriteOutlet.frame.height / 2)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // 다른 탭에 있는 게시판이나 갤러리 뷰에 갔다 와도 viewWillAppear()가 불리므로 네트워크-통신을 추가로 하지 않기 위한 예외처리입니다.
        // 모임 정보 데이터가 있다면, 아래 함수들을 읽지 말라는 명령.
        if self.groupInfo != nil { return }
        
        // Singleton에 있는 GroupPK 데려오기.
        guard let vSelectedGroupPK = JSDataCenter.shared.selectedGroupPK else {
            print("///// guardlet- vSelectedGroupPK")
            return
        }
        
        // Singleton에 저장된 모임 PK로 모임 정보와 공지사항 리스트를 가져옵니다.
        self.groupPK = vSelectedGroupPK
        
        // MARK: 모임 정보에 대한 통신 로직
        Alamofire.request(rootDomain + "/api/group/\(vSelectedGroupPK)", method: .get, parameters: nil, headers: nil).responseJSON { (response) in
            
            switch response.result {
            case .success(let value):
                print("///// Alamofire.request - response: ", value)
                
                let json = JSON(value)
                print("///// json: ", json)
                
                self.groupInfo = JSDataCenter.shared.findGroupInfo(ofResponseJSON: json)
                self.noticeList = JSDataCenter.shared.findNoticeList(ofResponseJSON: json["notice"])
                
                DispatchQueue.main.async {
                    self.mainTableView.reloadData()
                }
                
            case .failure(let error):
                print("///// Alamofire.request - error: ", error)
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // XLPagerTabStrip 에서 Tab 버튼에 Indicator 정보를 등록하는 Delegate 함수입니다.
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "모임 정보")
    }
    
    
    /**********************************/
    // MARK: -  모임 가입하기 버튼 Action  //
    /**********************************/
    
    @IBAction func buttonGroupJoin(_ sender: UIButton) {
        guard let vSelectedGroupPK = JSDataCenter.shared.selectedGroupPK else { return }
        guard let vToken = UserDefaults.standard.string(forKey: userDefaultsToken) else { return }
        
        let header = HTTPHeaders(dictionaryLiteral: ("Authorization", "Token \(vToken)"))
        
        Alamofire.request(rootDomain + "/api/group/\(vSelectedGroupPK)/join/",
            method: .post,
            parameters: nil,
            headers: header).responseJSON(completionHandler: {[unowned self] (response) in
                
                switch response.result {
                case .success(let value):
                    
                    let json = JSON(value)
                    print("/////8742 json: ", json)
                    
                    if json["joined"].boolValue {
                        DispatchQueue.main.async {
                            Toast(text: "모임에 가입되었습니다. :D").show()
                            self.mainTableView.reloadSections(IndexSet(integer: 3), with: .automatic)
                        }
                    } else {
                        DispatchQueue.main.async {
                            Toast(text: "이미 가입된 모임입니다. :)").show()
                        }
                    }
                    
                case .failure(let error):
                    print("/////8742 Alamofire.request - error: ", error)
                }
                
            })

    }
    
    /*******************************/
    // MARK: -  모임 관심 버튼 Action  //
    /*******************************/
    
    @IBAction func buttonGroupFavorite(_ sender: UIButton) {
        guard let vSelectedGroupPK = JSDataCenter.shared.selectedGroupPK else { return }
        guard let vToken = UserDefaults.standard.string(forKey: userDefaultsToken) else { return }
        
        let header = HTTPHeaders(dictionaryLiteral: ("Authorization", "Token \(vToken)"))
        
        Alamofire.request(rootDomain + "/api/group/\(vSelectedGroupPK)/like_toggle/",
            method: .post,
            parameters: nil,
            headers: header).responseJSON(completionHandler: { (response) in
                
                switch response.result {
                case .success(let value):
                    
                    let json = JSON(value)
                    print("/////5974 json: ", json)
                    
                    if json["created"].boolValue {
                        DispatchQueue.main.async {
                            Toast(text: "관심 모임에 등록되었습니다. :D").show()
                        }
                    } else {
                        DispatchQueue.main.async {
                            Toast(text: "관심 모임을 취소하였습니다. :X").show()
                        }
                    }
                    
                case .failure(let error):
                    print("/////5974 Alamofire.request - error: ", error)
                }
                
            })
    }
    
    
    /*********************************************/
    // MARK: -  UITableView Delegate & DataSource//
    /*********************************************/
    
    // MARK: section enum
    // 테이블 뷰의 섹션 구분을 위한 enum 입니다.
    enum sectionID:Int {
        case mainImageCell = 0
        case mainTextCell = 1
//        case joinLikeGroupCell = 2
        case noticeListCell = 2
        case memberListCell = 3
    }
    
    // MARK: Section Number
    // 모임 메인 화면의 섹션은 총 5개로 고정합니다.
    // 마지막 cell은 여백 cell.
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    // MARK: Row Number
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            
        // 공지사항 개수를 파악해 row를 그립니다.
        case sectionID.noticeListCell.rawValue:
            return self.noticeList?.count ?? 1
            
        // 회원목록 개수를 파악해 row를 그립니다.
        case sectionID.memberListCell.rawValue:
            guard let vMemberList = self.groupInfo?.memberList else { return 1 } // 회원목록 데이터가 비었을 경우의 예외처리
            if vMemberList.count == 0 {
                return 1 // 만약 회원목록이 0개더라도 "모임장"은 표시해주기 위해 row를 1로 리턴합니다.
            }else {
                return vMemberList.count + 1 // 회원목록 최상단에 "모임장"을 표시했으므로 count + 1만큼 리턴합니다.
            }
        default:
            return 1
        }
    }
    
    // MARK: Cell's custom height
    // 각 Cell의 AutoLayout을 Bottom까지 잘 설정한 후, UITableViewAutomaticDimension를 먹이면, 알아서 Cell 크기가 유동적으로(estimated) 설정됩니다.
    // heightForRowAt은 최소 단위, estimatedHeightForRowAt은 유동적인 단위를 주는 메소드입니다.
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    // MARK: Secion Title
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case sectionID.mainImageCell.rawValue:
            return nil // 모임 대표 이미지
        case sectionID.mainTextCell.rawValue:
            return "모임 소개"
        case sectionID.noticeListCell.rawValue:
            return "공지 사항"
        case sectionID.memberListCell.rawValue:
            return "회원 목록"
        default:
            return nil
        }
    }

    
    // MARK: Custom Cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
            
        // MARK: Custom Cell- 메인 이미지 셀
        case sectionID.mainImageCell.rawValue:
            let mainImageCell = tableView.dequeueReusableCell(withIdentifier: "1stMainImageCell", for: indexPath) as! JSGroupInfoMainImageCell
            
            guard let vMainImageUrl = self.groupInfo?.mainImageUrl else { return mainImageCell }
            
            if let imageURL = URL(string: vMainImageUrl) {
                let task = URLSession.shared.dataTask(with: imageURL, completionHandler: { (data, response, error) in
                    print("///// mainImageCell /////")
                    print("///// data: ", data ?? "no data")
                    print("///// response: ", response ?? "no data")
                    print("///// error: ", error ?? "no data")
                    
                    guard let realData = data else { return }
                    
                    DispatchQueue.main.async {
                        mainImageCell.mainImage.image = UIImage(data: realData)
                    }
                    
                })
                task.resume()
            }
            
            return mainImageCell
            
        // MARK: Custom Cell- 모임 소개 셀
        case sectionID.mainTextCell.rawValue:
            let mainTextCell = tableView.dequeueReusableCell(withIdentifier: "2ndMainTextCell", for: indexPath) as! JSGroupInfoMainTextCell
            mainTextCell.mainLabel.text = self.groupInfo?.mainText
            
            return mainTextCell
        
        // MARK: Custom Cell- 모임 공지사항 리스트 셀
        case sectionID.noticeListCell.rawValue:
            let noticeCell = tableView.dequeueReusableCell(withIdentifier: "4thNoticeListCell", for: indexPath) as! JSGroupInfoNoticeListCell
            guard let vNoticeList = self.noticeList else { return noticeCell }
            
            noticeCell.boardPK = vNoticeList[indexPath.row].boardPK
            noticeCell.labelTitle.text = vNoticeList[indexPath.row].title
            noticeCell.labelContent.text = vNoticeList[indexPath.row].content
            
            return noticeCell
            
        // MARK: Custom Cell- 모임 회원 목록 셀
        case sectionID.memberListCell.rawValue:
            let memberListCell = tableView.dequeueReusableCell(withIdentifier: "5thMemberListCell", for: indexPath) as! JSGroupInfoMemberListCell
            
            // 회원목록의 최상단에는 "모임장"을 표시합니다.
            if indexPath.row == 0 {
                memberListCell.textLabel?.text = self.groupInfo?.leaderName
                memberListCell.detailTextLabel?.text = "모임장"
            } else {
                memberListCell.textLabel?.text = self.groupInfo?.memberList?[indexPath.row-1] ?? "no data"
                memberListCell.detailTextLabel?.text = String(indexPath.row)
            }
            // 메모: 회원 프사도 보여주면 좋겠다.
            
            return memberListCell
            
        // MARK: Custom Cell- 테이블 뷰 여백 셀
        case 5:
            // MARK: [리팩토링 필요!]TableView의 최하단에 여백을 넣기 위한 cell 삽입.
            let basicCell = UITableViewCell()
            let babyView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 32))
            basicCell.contentView.addSubview(babyView)
            basicCell.selectionStyle = .none
            return basicCell
        default:
            let basicCell = UITableViewCell()
            return basicCell
        }
    }
    
    // MARK: DidSelectRowAt
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // 터치한 표시를 제거하는 액션
        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.section {
            
        // MARK: DidSelect- notice cell
        case sectionID.noticeListCell.rawValue: // 공지 사항 section
            let currentCell = tableView.cellForRow(at: indexPath) as! JSGroupInfoNoticeListCell
            print("///// noticePK: ", currentCell.boardPK ?? "no data")
            
            let nextVC = self.storyboard?.instantiateViewController(withIdentifier: "JSGroupBoardDetailViewController") as! JSGroupBoardDetailViewController
            nextVC.boardPK = currentCell.boardPK
            
            self.navigationController?.pushViewController(nextVC, animated: true)
        default:
            return
        }
    }
    
}
