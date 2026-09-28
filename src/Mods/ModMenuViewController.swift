import UIKit
#if DEV_MOD_MENU
final class ModMenuViewController:UIViewController,UITableViewDataSource,UITableViewDelegate {
    let registry:ModRegistry
    private let table=UITableView(frame:.zero,style:.insetGrouped)
    private var category=ModCategory.player
    init(registry:ModRegistry){self.registry=registry;super.init(nibName:nil,bundle:nil);modalPresentationStyle = .overFullScreen}
    required init?(coder:NSCoder){fatalError()}
    override func viewDidLoad(){super.viewDidLoad();view.backgroundColor=UIColor.black.withAlphaComponent(0.82);table.translatesAutoresizingMaskIntoConstraints=false;table.dataSource=self;table.delegate=self;view.addSubview(table);NSLayoutConstraint.activate([table.leadingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.leadingAnchor,constant:20),table.trailingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.trailingAnchor,constant:-20),table.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor,constant:20),table.bottomAnchor.constraint(equalTo:view.safeAreaLayoutGuide.bottomAnchor,constant:-20)])}
    private var items:[any ModAction]{registry.actions.values.filter{$0.category == category}.sorted{$0.title<$1.title}}
    func numberOfSections(in tableView:UITableView)->Int{ModCategory.allCases.count}
    func tableView(_ tableView:UITableView,numberOfRowsInSection section:Int)->Int{let c=ModCategory.allCases[section];return registry.actions.values.filter{$0.category == c}.count}
    func tableView(_ tableView:UITableView,titleForHeaderInSection section:Int)->String?{ModCategory.allCases[section].rawValue.uppercased()}
    func tableView(_ tableView:UITableView,cellForRowAt indexPath:IndexPath)->UITableViewCell{let c=ModCategory.allCases[indexPath.section];let a=registry.actions.values.filter{$0.category == c}.sorted{$0.title<$1.title}[indexPath.row];let cell=UITableViewCell(style:.value1,reuseIdentifier:nil);cell.textLabel?.text=a.title;if let t=a as? any ModToggle{cell.accessoryType=t.isEnabled ? .checkmark:.none};return cell}
    func tableView(_ tableView:UITableView,didSelectRowAt indexPath:IndexPath){let c=ModCategory.allCases[indexPath.section];let a=registry.actions.values.filter{$0.category == c}.sorted{$0.title<$1.title}[indexPath.row];a.execute();tableView.reloadRows(at:[indexPath],with:.none)}
}
#endif
