//
//  HxTimePicker.swift
//  ParkE
//
//  Created by Gaurav Keshre on 05/06/16.
//  Copyright © 2016 Hexagonal Loop. All rights reserved.
//

import Foundation
import UIKit

@objc protocol HxTimePickerDelegate: class{
    optional func heightForCellForPickerView(picker: HxTimePicker) -> CGFloat
    optional func selectionSeperatorColorForPickerView(picker: HxTimePicker) -> UIColor
    optional func selectionOverlayBackgroundColorForPickerView(picker: HxTimePicker) -> UIColor
    optional func fontForPickerView(picker: HxTimePicker) -> UIFont
}

private struct Constants{
    static let HourTableViewTag = 11234432
    static let MinuteTableViewTag = 11234433
    
    static let TopGradientName = "Top_Gradient_Layer"
    static let BottomGradientName = "Bottom_Gradient_Layer"
}
private struct Defaults{
    static let cellHeight               = CGFloat(60.0)
    static let selectionSeperatorColor  = UIColor(red: 0.0, green: 153/255, blue: 255/255, alpha: 1)
    static let selectionSeperatorHeight = CGFloat(1.0)
    static let selectionSeperatorMultiplier = CGFloat(0.8) // width will be 80% of tableview width
    static let overlayColor             = UIColor.clearColor()
    static let labelWidth               = CGFloat(10.0)
    static let font                     = UIFont.systemFontOfSize(14)
    
}

/// The class does not uses Autolayouts
class HxTimePicker: UIView{
    
    //MARK:- Variables
    //--------------------------------
    
    weak var delegate: HxTimePickerDelegate?
    
    private var rowHeight           : CGFloat = Defaults.cellHeight
    private var centralRowOffset    : CGFloat = 0
    
    //MARK:- IBOutlets
    //--------------------------------
    
    private weak var hr_tableView: UITableView?
    private weak var mn_tableView: UITableView?
    private weak var lblSeperator: UILabel?
    private weak var overlayView: UIView?
    
    //MARK:- LifeCycle
    //--------------------------------
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.prepareSubTableViews()
        self.hr_tableView?.separatorStyle = .None
        self.mn_tableView?.separatorStyle = .None
        
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        print("HxTimerPickerl - ayoutSubviews()")
        self.prepareSubTableViews()
        self.hr_tableView?.separatorStyle = .None
        self.mn_tableView?.separatorStyle = .None
        
    }
}

enum SelectionBarPosition{
    case top, bottom
    
    var tagOffset: Int{
        switch self {
        case .top:
            return 100
        case .bottom:
            fallthrough
        default:
            return 200
        }
    }
}

//MARK:- Setup the Timer Tables and label
//--------------------------------

extension HxTimePicker{
    private func prepareSubTableViews(){
        
        self.backgroundColor = UIColor.whiteColor()
  
        if let d_rowHeight = self.delegate?.heightForCellForPickerView?(self){
            self.rowHeight = d_rowHeight
        }else{
            self.rowHeight = Defaults.cellHeight
        }
        
        //top of the center row
        self.centralRowOffset = (self.frame.size.height - self.rowHeight) / 2
        
        
        ///TableViews
        let frame = self.bounds
        
        
        var tableFrame =  frame
        tableFrame.size.width = (self.frame.size.width - Defaults.labelWidth) / 2
        let htTable = self.datePickerTableViewWithFrame(tableFrame, tag: Constants.HourTableViewTag) //find by tag or create new
        
        
        tableFrame.origin.x = htTable.frame.origin.x + htTable.frame.size.width + Defaults.labelWidth
        let mtTable = self.datePickerTableViewWithFrame(tableFrame, tag: Constants.MinuteTableViewTag) //find by tag or create new
        
        
        // add only if this is newly creaeted tableview
        if htTable.superview == nil{
            self.addSubview(htTable); self.hr_tableView = htTable // because hr_table is weak
            self.addSubview(mtTable); self.mn_tableView = mtTable
        }

        
        /// Label ":"
        var labelFrame =  frame
        labelFrame.size.width = Defaults.labelWidth
        labelFrame.origin.x = self.hr_tableView?.frame.size.width ?? 0 // where hour table ends
        
        if self.lblSeperator == nil{
            let label = UILabel(frame: labelFrame)
            label.text = ":"
            label.textAlignment = .Center
            self.addSubview(label); self.lblSeperator = label
        }else{
            self.lblSeperator?.frame = labelFrame
        }
  
        /// Overlay
        var selectionViewFrame = self.bounds
        selectionViewFrame.origin.y = self.centralRowOffset
        selectionViewFrame.size.height = self.rowHeight
        
        
        if self.overlayView == nil{
            let overlay = UIView()
            overlay.userInteractionEnabled = false
            overlay.alpha = 0.2
            if let color = self.delegate?.selectionOverlayBackgroundColorForPickerView?(self){
                overlay.backgroundColor = color
            }else{
                overlay.backgroundColor = Defaults.overlayColor
            }
            self.addSubview(overlay); self.overlayView = overlay
        }
        
        self.overlayView?.frame = selectionViewFrame
    
        /// Seperator Bars
        
        
        guard let table1 = self.hr_tableView,
            let table2 = self.mn_tableView else{
                // No need for seperator
                return
        }
        
        let topbr1 = self.selectionSeperator(table1, position: .top)
        let topbr2 = self.selectionSeperator(table2, position: .top)
        let bottombr1 = self.selectionSeperator(table1, position: .bottom)
        let bottombr2 = self.selectionSeperator(table2, position: .bottom)
        
        if topbr1.superview == nil{
            self.addSubview(topbr1)
            self.addSubview(topbr2)
            self.addSubview(bottombr1)
            self.addSubview(bottombr2)
        }
        
        /// Layers
        self.createAndAddVerticalFadeOutGradient()
        self.createAndAddVerticalFadeOutGradient(true)
        
    }
}



//MARK:- TableView And ScrollView Delegate
//--------------------------------

extension HxTimePicker: UITableViewDelegate, UITableViewDataSource{
    
    
    //MARK:- UITableViewDelegate Methods
    //--------------------------------
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.hr_tableView{
            // return total hours
            return 24
        }
        
        // return total minutes
        return 60
    }
    
    
    //MARK:- UITableViewDataSource Methods
    //--------------------------------
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell
        
        if let _cell = tableView.dequeueReusableCellWithIdentifier("Cell"){
            cell = _cell
        }else{
            cell = UITableViewCell(style: .Default, reuseIdentifier: "Cell")
        }
        
        let til = "\(String(format: "%02d", indexPath.row))"
        cell.textLabel?.text = til
//        cell.textLabel?.adjustsFontSizeToFitWidth = true
//        cell.textLabel?.minimumScaleFactor = 0.5
        
        if let ffont = self.delegate?.fontForPickerView?(self){
            cell.textLabel?.font = ffont
        }else{
            cell.textLabel?.font = Defaults.font
        }
        
        cell.textLabel?.textAlignment = .Center
        cell.selectionStyle = .None
        cell.textLabel?.textColor = UIColor.blackColor()
        cell.backgroundColor = UIColor.whiteColor()
        return cell
    }
    
    
    
    
    //MARK:- UIScrollViewDelege Methods
    //--------------------------------
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate, let tableView = scrollView as? UITableView{
            self.alignTableViewToRowBoundary(tableView)
        }
        
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if let tableView = scrollView as? UITableView{
            self.alignTableViewToRowBoundary(tableView)
        }
    }
    
    
    //MARK:- Convenience Method for scroling
    //--------------------------------
    private func alignTableViewToRowBoundary(tableView: UITableView){
        let relativeOffset: CGPoint = CGPointMake(0, tableView.contentOffset.y + tableView.contentInset.top)
        let row: Int = Int(ceil(relativeOffset.y / tableView.rowHeight))
        print("----")
        print("div: \(relativeOffset.y / tableView.rowHeight)")
        print("row: \(row)")
        print("----")
        self.selectRow(row, inTableView: tableView, animated: true, updateComponents: true)
    }
    
    
    private func selectRow(row: Int, inTableView tableView: UITableView, animated:Bool, updateComponents: Bool) {
        
        let alignedOffset: CGPoint = CGPointMake(0, CGFloat(row) * tableView.rowHeight - tableView.contentInset.top)
        
        tableView.setContentOffset(alignedOffset, animated: animated)
        
        guard updateComponents else{
            return
        }
        
        tableView.reloadData()
    }
    
}



//MARK:- Factory Extension
//--------------------------------

extension HxTimePicker{
    
    //MARK: Table Factory
    //--------------------------------
    
    private func datePickerTableViewWithFrame(frame: CGRect, tag: Int) -> UITableView{
    
        if let extView = self.viewWithTag(tag), let existingTableView = extView as? UITableView{
            existingTableView.frame = frame
            return existingTableView
        }else{
            
            let tableView = UITableView(frame: frame, style: .Plain)
            tableView.tag = tag
            tableView.rowHeight = CGFloat(self.rowHeight)
            tableView.contentInset = UIEdgeInsetsMake(self.centralRowOffset, 0, self.centralRowOffset, 0);
            
            tableView.delegate = self;
            tableView.dataSource = self;
            
            tableView.showsVerticalScrollIndicator = false
            tableView.separatorStyle = .None
            return tableView;
        }
    }
    
    
    
    //MARK: Seperator Factory
    //--------------------------------
    
    private func selectionSeperator(tableView: UITableView, position: SelectionBarPosition) -> UIView {
        
        let tag = tableView.tag + position.tagOffset
        
        var sepFrame = tableView.frame
        sepFrame.size.height = Defaults.selectionSeperatorHeight
        sepFrame.size.width  = Defaults.selectionSeperatorMultiplier * tableView.frame.size.width
        
        let topOffset = (position == .top) ? 0 : tableView.rowHeight
        sepFrame.origin.y = self.centralRowOffset + topOffset
        let seperator: UIView
        if let existingSeperator = self.viewWithTag(tag){
            seperator = existingSeperator
        }else{
            seperator = UIView()
            seperator.tag = tag
            if let color = self.delegate?.selectionSeperatorColorForPickerView?(self){
                seperator.backgroundColor = color
            }else{
                seperator.backgroundColor = Defaults.selectionSeperatorColor
            }
        }
        // Frame Tuning
        seperator.frame            = sepFrame
        seperator.center.x         = tableView.frame.origin.x + tableView.frame.size.width / 2
        seperator.center.y		  -= 1.0
        return seperator
    }
    

    
    //MARK: Gradient Factory
    //--------------------------------

    private func createAndAddVerticalFadeOutGradient(inverted: Bool = false){
      //  return
        let h: CGFloat      = 35.0
        let sourceColor     = UIColor.whiteColor().CGColor
        let destColor       = UIColor.whiteColor().colorWithAlphaComponent(0.1) .CGColor
        var bounds          = self.bounds; bounds.size.height = h
        
        let name = inverted ? Constants.BottomGradientName : Constants.TopGradientName
        
        let layer: CAGradientLayer
        
        if let extLayer = self.layerByName(name) as? CAGradientLayer{
            layer = extLayer
        }else{
            layer = CAGradientLayer()
            layer.colors =  inverted ? [destColor, sourceColor] : [sourceColor, destColor]
            self.layer.addSublayer(layer)
        }
        
        if inverted{
            bounds.origin.y = self.bounds.size.height - h
        }
        layer.frame = bounds
    }
}


//MARK:- General
//--------------------------------

extension HxTimePicker{
    func layerByName(name: String) -> CALayer?{
        guard let subLayers = self.layer.sublayers else{
            return nil
        }
        for layer in subLayers {
            if layer.name == name{
                return layer
            }
        }
        return nil
    }
}