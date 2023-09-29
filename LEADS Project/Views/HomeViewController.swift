//
//  ViewController.swift
//  LEADS Project
//
//  Created by Md Shofiulla on 26/9/23.
//

import UIKit
import Combine

class HomeViewController: UIViewController {
    
    lazy var mainCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        var collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        collectionView.contentInset = .init(top: 0, left: 0, bottom: 20, right: 0)
        collectionView.register(CategoryCollectionCell.self, forCellWithReuseIdentifier: CategoryCollectionCell.identifier)
        collectionView.register(ProductCollectionCell.self, forCellWithReuseIdentifier: ProductCollectionCell.identifier)
        collectionView.register(NavigationHeaderReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NavigationHeaderReusableView.identifier)
        return collectionView
    }()
    
    private typealias DataSource = UICollectionViewDiffableDataSource<HomeViewModel._Sections<AnyHashable>, AnyHashable>
    private var dataSource: DataSource?
    private let layout = SectionLayouts()
    private let viewModel = HomeViewModel()
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        addViews()
        setupBindings()
        setupViews()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
}

extension HomeViewController {
    private func setupBindings() {
        self.viewModel.$viewState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedState in
                switch updatedState {
                    case .loaded:
                        self?.applyData()
                    case .error(let message):
                        debugPrint(message)
                    default:
                        break
                }
            }
            .store(in: &cancellables)
    }
}
extension HomeViewController {
    private func addViews(){
        self.view.addSubview(mainCollectionView)
        addConstraints()
    }
    private func addConstraints(){
        NSLayoutConstraint.activate([
            mainCollectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
            mainCollectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            mainCollectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            mainCollectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
}
extension HomeViewController {
    private func setupViews(){
        setupCollectionView()
    }
    private func applyData() {
        var snapshot = NSDiffableDataSourceSnapshot<HomeViewModel._Sections<AnyHashable>, AnyHashable>()
        self.viewModel.sections.forEach { section in
            guard !section.items.isEmpty else {return}
            snapshot.appendSections([section])
            snapshot.appendItems(section.items, toSection: section)
        }
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
    
    
    private func setupCollectionView() {
        mainCollectionView.collectionViewLayout = makeLayout()
        mainCollectionView.delegate = self
        setupCollectionViewDataSource()
    }
    private func makeLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            let sectionType = self?.dataSource?.snapshot().sectionIdentifiers[sectionIndex].sectionItem
            switch sectionType {
                case .category:
                    return self?.layout.categoryVerticalSectionLayout(showHeader: true)
                case .product:
                    return self?.layout.productVeritcalSectionLayout()
            case .none:
                return self?.layout.defaultSectionLaout()
            }
        }
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 8
        layout.configuration = config
        return layout
        
    }
}
extension HomeViewController: UICollectionViewDelegate {
   
}

extension HomeViewController {
    private func setupCollectionViewDataSource(){
        dataSource = DataSource(collectionView: mainCollectionView) {  collectionView, indexPath, item in
            if let category = item as? String {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCollectionCell.identifier, for: indexPath) as? CategoryCollectionCell else { fatalError("Can't find cell with identifier CategoryCollectionCell")}
                return cell
            }
            if let product = item as? Int {
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCollectionCell.identifier, for: indexPath) as? ProductCollectionCell else { fatalError("Can't find cell with identifier ProductCollectionCell")}
                return cell
            }
            return UICollectionViewCell()
          
        }
        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NavigationHeaderReusableView.identifier, for: indexPath) as? NavigationHeaderReusableView else {  fatalError("Could not dequeue sectionHeader")}
            return sectionHeader
        }
    }
}
