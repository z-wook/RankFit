//
//  MyDetailViewController.swift
//  RankFit
//
//  Created by 한지욱 on 2023/01/02.
//

import UIKit
import Combine

class MyDetailViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    let viewModel = MyDetailViewModel()
    var exercise: String!
    
    typealias Item = OptionRankInfo // MyRank이지만 OptionRankInfo와 같은 형식의 구조체이므로 재활용 했음
    enum Section {
        case main
    }
    
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    let reporting = PassthroughSubject<String, Never>()
    var subscriptions = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backButtonDisplayMode = .minimal
        self.navigationItem.title = exercise
        configureCollectionView()
        bind()
        indicator.startAnimating()
    }
    
    @IBAction func reporting(_ sender: UIButton) {
        reportUser(index: sender.tag)
    }
    
    func myInfo(exInfo: [String : String]) {
        self.exercise = exInfo["exName"]
        viewModel.getMyDetailRank(info: exInfo)
    }
    
    private func bind() {
        viewModel.receiveSubject.receive(on: RunLoop.main).sink { info in
            guard let info = info else { return }
            self.indicator.stopAnimating()
            if info.isEmpty {
                self.applyItems(items: [])
                return
            }
            self.applyItems(items: info)
        }.store(in: &subscriptions)
        
        reporting.receive(on: RunLoop.main).sink { result in
            switch result {
            case "done":
                self.showAlert(title: "신고 완료", message: "확인 후 빠르게 조치하겠습니다.")
                return
            case "already":
                self.showAlert(title: "신고 완료된 사용자", message: "이미 신고 처리된 사용자입니다.")
                return
            default: // fail
                self.showAlert(title: "신고 실패", message: "잠시 후 다시 시도해 주세요.")
                return
            }
        }.store(in: &subscriptions)
    }
}

extension MyDetailViewController {
    private func reportUser(index: Int) {
        guard let rankList = viewModel.receiveSubject.value else { return }
        let nickName = rankList[index].Nickname

        let alert = UIAlertController(title: "신고 사유 선택", message: nil, preferredStyle: .actionSheet)
        let reportProfile = UIAlertAction(title: "부적절한 프로필 사진", style: .default) { _ in
            configServer.reportUser(nickName: nickName, reason: 0, subject: self.reporting)
        }
        let reportNickName = UIAlertAction(title: "부적절한 닉네임", style: .default) { _ in
            configServer.reportUser(nickName: nickName, reason: 1, subject: self.reporting)
        }
        let reportScore = UIAlertAction(title: "랭킹 오류 / 랭킹 악용 의심", style: .default) { _ in
            configServer.reportUser(nickName: nickName, reason: 2, subject: self.reporting)
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alert.addAction(reportProfile)
        alert.addAction(reportNickName)
        alert.addAction(reportScore)
        alert.addAction(cancel)
        present(alert, animated: true)
    }
    
    private func configureCollectionView() {
        datasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyDetailRankCell", for: indexPath) as? MyDetailRankCell else { return nil }
            cell.config(rank: itemIdentifier.Ranking, nickname: itemIdentifier.Nickname, score: itemIdentifier.Score)
            cell.reportBtn.tag = indexPath.item
            return cell
        })
        collectionView.collectionViewLayout = layout()

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems([], toSection: .main)
        datasource.apply(snapshot)
        collectionView.delegate = self
    }
    
    private func applyItems(items: [OptionRankInfo]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        datasource.apply(snapshot)
    }

    private func layout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        section.interGroupSpacing = 10
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func showAlert() {
        let alert = UIAlertController(title: "에러", message: "잠시 후 다시 시도해 주세요.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        }
        alert.addAction(ok)
        present(alert, animated: true)
    }
    
    private func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default)
        alert.addAction(ok)
        present(alert, animated: true)
    }
}

extension MyDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 { return }
        let sb = UIStoryboard(name: "MyDetail", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "UserDetailViewController") as! UserDetailViewController
        let value = viewModel.receiveSubject.value
        guard let value = value else {
            print("MyDetailVC/didSelectItemAt / value == nil")
            configFirebase.errorReport(type: "MyDetailVC.collectionView", descriptions: "value == nil")
            showAlert()
            return
        }
        vc.userInfo(nickName: value[indexPath.item].Nickname)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
