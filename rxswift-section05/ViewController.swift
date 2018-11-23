import UIKit

//class ViewController: UIViewController {
//
//    @IBOutlet weak var countLabel: UILabel!
//
//    private var viewModel: CounterViewModel!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        viewModel = CounterViewModel()
//    }
//
//    @IBAction func countUp(_ sender: Any) {
//        viewModel.incrementCount(callback: { [weak self] count in
//            self?.updateCountLabel(count)
//        })
//    }
//
//    @IBAction func countDown(_ sender: Any) {
//        viewModel.decrementCount(callback: { [weak self] count in
//            self?.updateCountLabel(count)
//        })
//    }
//
//    @IBAction func countReset(_ sender: Any) {
//        viewModel.resetCount(callback: { [weak self] count in
//            self?.updateCountLabel(count)
//        })
//    }
//
//    private func updateCountLabel(_ count: Int) {
//        countLabel.text = String(count)
//    }
//}
//
//class CounterViewModel {
//    private(set) var count = 0
//
//    func incrementCount(callback: (Int) -> ()) {
//        count += 1
//        callback(count)
//    }
//
//    func decrementCount(callback: (Int) -> ()) {
//        count -= 1
//        callback(count)
//    }
//
//    func resetCount(callback: (Int) -> ()) {
//        count = 0
//        callback(count)
//    }
//}

//
//protocol CounterDelegate {
//    func updateCount(count: Int)
//}
//
//class CounterPresenter {
//    private var count = 0 {
//        didSet {
//            delegate?.updateCount(count: count)
//        }
//    }
//
//    private var delegate: CounterDelegate?
//
//    func attachView(_ delegate: CounterDelegate) {
//        self.delegate = delegate
//    }
//
//    func detachView() {
//        self.delegate = nil
//    }
//
//    func incrementCount() {
//        count += 1
//    }
//
//    func decrementCount() {
//        count -= 1
//    }
//
//    func resetCount() {
//        count = 0
//    }
//}
//
//class ViewController: UIViewController {
//
//    @IBOutlet weak var countLabel: UILabel!
//
//    private let presenter = CounterPresenter()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        presenter.attachView(self)
//    }
//
//    @IBAction func countUp(_ sender: Any) {
//        presenter.incrementCount()
//    }
//
//    @IBAction func countDown(_ sender: Any) {
//        presenter.decrementCount()
//    }
//
//    @IBAction func countReset(_ sender: Any) {
//        presenter.resetCount()
//    }
//}
//
//extension ViewController: CounterDelegate {
//    func updateCount(count: Int) {
//        countLabel.text = String(count)
//    }
//}
//

import RxSwift
import RxCocoa

struct CounterViewModelInput {
    let countUpButton: Observable<Void>
    let countDownButton: Observable<Void>
    let countResetButton: Observable<Void>
}

protocol CounterViewModelOutput {
    var counterText: Driver<String?> { get }
}

protocol CounterViewModelType {
    var outputs: CounterViewModelOutput? { get }
    func setup(input: CounterViewModelInput)
}

class CounterRxViewModel: CounterViewModelType {
    var outputs: CounterViewModelOutput?
    
    private let countRelay = BehaviorRelay<Int>(value: 0)
    private let initialCount = 0
    private let disposeBag = DisposeBag()
    
    init() {
        self.outputs = self
        resetCount()
    }
    
    func setup(input: CounterViewModelInput) {
        input.countUpButton
            .subscribe(onNext: { [weak self] in
                self?.incrementCount()
            })
            .disposed(by: disposeBag)
        
        input.countDownButton
            .subscribe(onNext: { [weak self] in
                self?.decrementCount()
            })
            .disposed(by: disposeBag)
        
        input.countResetButton
            .subscribe(onNext: { [weak self] in
                self?.resetCount()
            })
            .disposed(by: disposeBag)
        
    }
    
    private func incrementCount() {
        let count = countRelay.value + 1
        countRelay.accept(count)
    }
    
    private func decrementCount() {
        let count = countRelay.value - 1
        countRelay.accept(count)
    }
    
    private func resetCount() {
        countRelay.accept(initialCount)
    }
}

extension CounterRxViewModel: CounterViewModelOutput {
    var counterText: Driver<String?> {
        return countRelay
            .map { "Rxパターン:\($0)" }
            .asDriver(onErrorJustReturn: nil)
    }
}


class ViewController: UIViewController {
    
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var countUpButton: UIButton!
    @IBOutlet weak var countDownButton: UIButton!
    @IBOutlet weak var countResetButton: UIButton!
    
    private let disposeBag = DisposeBag()
    
    private var viewModel: CounterRxViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
    }
    
    private func setupViewModel() {
        viewModel = CounterRxViewModel()
        let input = CounterViewModelInput(
            countUpButton: countUpButton.rx.tap.asObservable(),
            countDownButton: countDownButton.rx.tap.asObservable(),
            countResetButton: countResetButton.rx.tap.asObservable()
        )
        viewModel.setup(input: input)
        
        viewModel.outputs?.counterText
            .drive(countLabel.rx.text)
            .disposed(by: disposeBag)
    }
}
