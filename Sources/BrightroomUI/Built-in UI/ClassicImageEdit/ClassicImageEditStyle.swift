//
// Copyright (c) 2018 Muukii <muukii.app@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

public struct ClassicImageEditStyle: Equatable {
  
  public static func == (lhs: ClassicImageEditStyle, rhs: ClassicImageEditStyle) -> Bool {
    return
    lhs.backgroundColor == rhs.backgroundColor &&
    lhs.onBackgroundColor == rhs.onBackgroundColor &&
    lhs.inactiveColor == rhs.inactiveColor &&
    lhs.activeColor == rhs.activeColor &&
    lhs.disabledColor == rhs.disabledColor &&
    lhs.black == rhs.black &&
    lhs.control.backgroundColor == rhs.control.backgroundColor
  }

  public static let `default` = ClassicImageEditStyle()

  public struct Control {

//    public var backgroundColor = UIColor(white: 0.98, alpha: 1)
    public var backgroundColor = UIColor.clear

    public init() {

    }
  }

  public var control = Control()
  
  public var black = UIColor(white: 0.05, alpha: 1)
  
  public var backgroundColor: UIColor = .black
  public var onBackgroundColor: UIColor = .white
  public var inactiveColor: UIColor = .systemGray
  public var activeColor: UIColor = .systemYellow
  public var disabledColor: UIColor = .darkGray

  public init() {

  }

}
