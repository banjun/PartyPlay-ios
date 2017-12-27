//
//  ViewController.swift
//  PartyPlay
//
//  Created by BAN Jun on 8/15/15.
//  Copyright © 2015 banjun. All rights reserved.
//

import UIKit


class ViewController: UITableViewController {
    let browser = PartyPlayServiceBrowser(name: UIDevice.current.name)
    
    init() {
        super.init(style: .grouped)
        
        title = LocalizedString.appName
        browser.onStateChange = { [weak self] in
            self?.tableView.reloadData()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Section.NearbyServers.cellID)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Section.BecomeAServer.cellID)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        browser.start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        browser.stop()
    }
    
    // MARK: Table View
    
    enum Section: Int {
        case NearbyServers
        case BecomeAServer
        
        var cellID: String {
            switch self {
            case .NearbyServers: return "NearbyServers"
            case .BecomeAServer: return "BecomeAServer"
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .NearbyServers: return browser.sessions.count
        case .BecomeAServer: return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .NearbyServers where browser.sessions.count > 0: return LocalizedString.nearbyServers
        case .NearbyServers: return LocalizedString.noServersNearby
        case .BecomeAServer: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Section(rawValue: indexPath.section)!
        let cell = tableView.dequeueReusableCell(withIdentifier: section.cellID, for: indexPath as IndexPath)
        switch section {
        case .NearbyServers:
            let session = browser.sessions[indexPath.row]
            cell.textLabel?.text = session.server?.displayNameWithoutPrefix ?? "Connecting to server..."
            // cell.detailTextLabel?.text = "\(session.clients.count) clients: " + ", ".join(session.clients.map({$0.displayNameWithoutPrefix}))
            cell.accessoryType = .detailDisclosureButton
        case .BecomeAServer:
            cell.textLabel?.text = LocalizedString.becomeAServer
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = Appearance.tintColor
            break
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        switch Section(rawValue: indexPath.section)! {
        case .NearbyServers:
            let session = browser.sessions[indexPath.row]
            guard let server = session.server else { break }
            let vc = ClientViewController(client: PartyPlayClient(session: session, server: server))
            navigationController?.pushViewController(vc, animated: true)
        case .BecomeAServer:
            let ac = UIAlertController(title: nil, message: LocalizedString.confirmBecomeAServer, preferredStyle: .actionSheet)
            ac.addAction(UIAlertAction(title: LocalizedString.becomeAServer, style: .default) { _ in
                let svc = ServerViewController()
                let nc = UINavigationController(rootViewController: svc)
                self.present(nc, animated: true, completion: nil)
                })
            ac.addAction(UIAlertAction(title: LocalizedString.cancel, style: .cancel, handler: nil))
            present(ac, animated: true, completion: nil)
        }
    }
}
