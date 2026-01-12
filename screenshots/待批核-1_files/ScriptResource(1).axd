/*
Infragistics WebNavigator Script: ig_webmenu.js
Version <SUCCESSFUL_COMPONENT_VERSION>
Copyright (c) 2002-2006 Infragistics, Inc. All Rights Reserved.  
*/

var ig_menuPopup = null;
var ig_oActiveMenu = null;
var ig_oCurrentSubMenu;
var igmenu_initialized = false;
/* D.M. BR23107 6/6/07 - Safari doesn't support isPrototypeOf so these flags need to be used */
var ig_isMenuCreated = false;
var ig_isMenuItemCreated = false;
var ig_isSubmenuCreated = false;
/* End BR23107*/

if (typeof (igmenu_array) != "object")
	var igmenu_array = [];
if (typeof (igmenu_itemArray) != "object")
	var igmenu_itemArray = [];
if (typeof (igmenu_submenuArray) != "object")
	var igmenu_submenuArray = [];
/*
if(typeof(igmenu_panelArray) != "object")
var igmenu_panelArray = [];
*/
var iframeCount = 0;
var igmenu_dropDowns;

// Warning: Private functions for internal component usage only
// The functions in this section are not intended for general use and are not supported
// or documented.
function igmenu_podmouseover(evnt)
{
	if (evnt == null)
		evnt = window.event;
	var eItem = ig_fromEvent(evnt);
	var oMenu = igmenu_getMenuByItemId(eItem.id);
	var oItem = igmenu_getItemById(eItem.id);

	if (oItem.isSeparator())
	{
		return;
	}
	if (!oItem.isEnabled())
		return;

	oItem.hover();
	ig_inMenu = true;


}
function igmenu_podmouseout(evnt)
{
	var eItem = ig_fromEvent(evnt);
	var e = ig.getSourceElement(evnt);
	if (ig_isMouseOutSourceAChild(evnt, eItem))
		return;
	var oItem = igmenu_getItemById(eItem.id);
	var oMenu = oItem.WebMenu;

	if (oItem.isSeparator())
	{
		return;
	}
	if (!oItem.isEnabled())
		return;
	if (!oItem.getSelected())
		oItem.unhover(true);
	ig_inMenu = false;


}
function igmenu_podmousedown(evnt)
{
	ig_inMenu = true;
	ig_startClick = true;
}
function igmenu_podmouseup(evnt)
{
	if (ig_startClick)
	{
		var eItem = ig_fromEvent(evnt);
		var e = ig.getSourceElement(evnt);
		if (ig_isMouseOutSourceAChild(evnt, eItem))
			return;
		var oItem = igmenu_getItemById(eItem.id);
		var oMenu = oItem.WebMenu;

		if (oMenu._uninitialized == true)
		{
			oMenu._uninitialized = false;
			if (!oMenu.viewport)
			{
				oMenu.viewport = new ig_viewport();
				oMenu.viewport.createViewport(oMenu._frameElement, ViewportOrientationEnum.Horizontal);
				oMenu.viewport.transferPositionToDiv(oMenu._frameElement);
			}
		}
		if (!oItem.isEnabled())
			return;
		var oChildSubMenu = oItem.getChildSubMenu();
		var oOwnerSubMenu = oItem.getOwnerSubMenu();
		//if(oOwnerSubMenu.element.style.width == "")
		oOwnerSubMenu.element.style.width = oOwnerSubMenu.element.offsetWidth.toString() + "px";
		if (oChildSubMenu != null)
		{
			oChildSubMenu.drillDownDisplay(oOwnerSubMenu, oItem);
			return;
		}
	}
	igmenu_mouseup(evnt);
}

function igmenu_podheadermousedown(evnt)
{
}
function igmenu_podheadermouseup(evnt)
{
	var e = ig.getSourceElement(evnt);
	var parent = e.parentNode;
	var eSubMenu;
	while (parent)
	{
		if (parent.getAttribute("submenu"))
		{
			eSubMenu = parent;
			break;
		}
		parent = parent.parentNode;
	}
	var oSubMenu = igmenu_getSubMenuById(null, eSubMenu.id);
	oSubMenu.drillDownUnDisplay();

}

function igmenu_submenumouseover(evnt)
{
	clearTimeout(igmenu_clearMenuTimerId);
	clearCurrentMenu = false;
}
function igmenu_submenumouseout(evnt)
{
	var e = ig.getSourceElement(evnt);
	while (!e.id)
		e = e.parentNode;
	var oMenu = igmenu_getMenuByItemId(e.id);

	clearTimeout(igmenu_clearMenuTimerId);
	clearCurrentMenu = true;
	if (oMenu)
		igmenu_clearMenuTimerId = setTimeout('clearTimerExpired()', oMenu.ExpandEffects.RemovalDelay);
	else
		alert("oMenu == null");
}

// private - implements mouseover event handling for the menu
function igmenu_mouseover(evnt)
{
	if (evnt == null)
		evnt = window.event;
	var eItem = ig_fromEvent(evnt);
	ig_inMenu = true;
	var oMenu = igmenu_getMenuByItemId(eItem.id);
	var oItem = igmenu_getItemById(eItem.id);
	if (oItem._hovered)
	{
		clearTimeout(igmenu_clearMenuTimerId);
		return;
	}
	if (ig_oActiveMenu && ig_oActiveMenu != oMenu)
	{
		ig_oActiveMenu.hideSubMenus();
		ig_oActiveMenu = oMenu;
	}
	clearCurrentMenu = false;

	if (oItem.isSeparator())
	{
		return;
	}
	if (!oItem.getEnabled())
	{
		if (oItem.isTopLevelItem())
			oMenu.hideSubMenus();
		else
		{
		    /* AS fix for 21120 2009-10-19 */
		    /* Why shall we close submenus if user has hovered over a disabled menu item ?*/
			/*var oOwnerSubMenu = oItem.getOwnerSubMenu();*/
			/*oOwnerSubMenu.dismissDescendantSubMenus();*/
		}
		return;
	}
	oItem.hover();

	if (oMenu.isHorizontal() &&
		oItem.isTopLevelItem() &&
		(oMenu.isRichClient() || oMenu.isXPClient()) &&
		!oMenu.TopHoverStarted)
		return;

	var oChildSubMenu = oItem.getChildSubMenu();
	var oOwnerSubMenu = oItem.getOwnerSubMenu();
	clearTimeout(igmenu_displayMenuTimerId);
	if (oChildSubMenu != null)
	{
		if (oMenu.isHorizontal() && oItem.isTopLevelItem())
		{
			oChildSubMenu.show(oItem);
		}
		else
		{
			/*D.M. 4/23/2007 BR20119, BR22300 - Removed fix for BR20119, alerts should not be used in ItemHover event */
			oItem.__displaySubMenu(oChildSubMenu);
		}
	}
	else
		oOwnerSubMenu.dismissDescendantSubMenus();
}

var igmenu_displayMenuTimerId;
var igmenu_clearMenuTimerId;
/* D.M. 11/11/2008 - Bug 9406  */
var igmenu_displaySubMenuTimerId;

// private - implements mouseout event handling
function igmenu_mouseout(evnt)
{
	ig_inMenu = false;
	var eItem = ig_fromEvent(evnt);

	var e = ig.getSourceElement(evnt);
	if (ig_isMouseOutSourceAChild(evnt, eItem))
		return;
	var oItem = igmenu_getItemById(eItem.id);
	var oMenu = oItem.WebMenu;

	if (oItem.isSeparator())
	{
		clearCurrentMenu = true;
		if (ig_csom.IsIE)
		{
			clearTimeout(igmenu_clearMenuTimerId);
			igmenu_clearMenuTimerId = setTimeout('clearTimerExpired()', oMenu.ExpandEffects.RemovalDelay);
		}
		return;
	}
	if (!oItem.isEnabled())
		return;
	if (!oItem.getSelected())
		oItem.unhover(true);

	clearTimeout(igmenu_displayMenuTimerId);
	clearCurrentMenu = true;
	clearTimeout(igmenu_clearMenuTimerId);
	igmenu_clearMenuTimerId = setTimeout('clearTimerExpired()', oMenu.ExpandEffects.RemovalDelay);
	ig_cancelEvent(evnt);
}

// private - initializes the menu object on the client
function igmenu_initMenu(menuId)
{
	igmenu_itemArray = []; /* VS 10/03/2006 ?? */
	if (!igmenu_initialized)
	{
		igmenu_initialize();
		igmenu_initialized = true;
	}

	ig_oActiveMenu = null;
	var oMenu = igmenu_array[menuId];
	if (oMenu)
	{
		var abs = oMenu._abs; /*VS 11/20/2006 remove submenus from body, which were moved from local parent */
		var i = abs ? abs.length : 0;
		while (i-- > 0)
			if (abs[i].parentNode)
			abs[i].parentNode.removeChild(abs[i]);
		oMenu._abs = null;
		oMenu.cancelAnimations();
		for (var id in igmenu_submenuArray)
		{
			var o = igmenu_submenuArray[id];
			if (o && o.WebMenu && o.WebMenu.MenuName == menuId)
			{
				/* VS 10/21/2008 Bug 9269 */
				var tp = o.transPanel;
				if (tp)
				{
					tp.hide();
					var elem = tp.Element;
					if (elem)
						elem.parentNode.removeChild(elem);
					delete tp.Element;
					delete o.transPanel;
				}
				igmenu_submenuArray[id] = null;
			}
		}
		oMenu.base = oMenu.Events = null;
		ig_dispose(oMenu);
	}
	var menuElement = igmenu_getElementById(menuId + "_MainM");
	oMenu = igmenu_Create(menuElement, eval("igmenu_" + menuId + "_Menu"));
	igmenu_array[menuId] = oMenu;
	oMenu.fireEvent(oMenu.Events.InitializeMenu, "(\"" + menuId + "\");");

	if (!(ig_csom.IsIE5 || ig_csom.IsIE55 || ig_csom.IsIE6))
		oMenu.HideDropDowns = false;

	if (oMenu.HideDropDowns == true && igmenu_dropDowns == null)
	{
		igmenu_dropDowns = document.all.tags("SELECT");
	}

	if (!oMenu._isSection508Compliant)
		oMenu.Element.tabIndex = 0;

	oMenu.hasFrame = false;
	var frameElement = menuElement;
	if (frameElement.parentNode.getAttribute('menuframe') == "1")
	{
		frameElement = frameElement.parentNode;
		oMenu.hasFrame = true;
	}
	if (oMenu.isDrillDown())
	{
		if (frameElement.offsetWidth == 0 && frameElement.offsetHeight == 0)
		{
			oMenu._uninitialized = true;
			oMenu._frameElement = frameElement;
		}
		else
			if (!oMenu.viewport)
		{
			oMenu.viewport = new ig_viewport();
			oMenu.viewport.createViewport(frameElement, ViewportOrientationEnum.Horizontal);
			oMenu.viewport.transferPositionToDiv(frameElement);
		}
	}
	if (ig_csom.IsIE)
	{
		if (!oMenu.Element.isDisabled)
			igmenu_initHandlers(oMenu, oMenu.getItems());
	}
	else
		igmenu_initHandlers(oMenu, oMenu.getItems());
	if (!oMenu.Element._old)
	{
		ig_shared.addEventListener(oMenu.Element, "mouseover", igmenu_submenumouseover, true);
		ig_shared.addEventListener(oMenu.Element, "mouseout", igmenu_submenumouseout, true);
		/* D.M. BR21320 10/23/2006 - Added separate keyboard navigation for section 508 support
		* see igmenu_keyboardWith508Support for details. */
		if (oMenu._isSection508Compliant)
		{
			ig_shared.addEventListener(oMenu.Element, "focus", igmenu_keyboardWith508Support.onfocus, true);
			ig_shared.addEventListener(oMenu.Element, "keydown", igmenu_keyboardWith508Support.menuKeydown, true);
			ig_shared.addEventListener(oMenu.Element, "focus", igmenu_keyboardWith508Support.onmenufocus, true);
			ig_shared.addEventListener(oMenu.Element, "blur", igmenu_keyboardWith508Support.onmenublur, true);
		}
		else
			ig_shared.addEventListener(oMenu.Element, "focus", igmenu_keyboard.onfocus, true);
	}
	oMenu.Element._old = true;
	oMenu.MenuName = menuId;

	oMenu.MenuLoaded = true;
	return oMenu;
}

// private - constructor for the menu object
function igmenu_Create(menuElement, props)
{

	var createMenu = false;
	/* D.M. BR23107 6/6/07 - We have to do this because Safari lacks support for the
	isPrototypeOf method.  This way if the method fails we fall through and use
	flags instead.
	*/
	try
	{
		if (!ig_WebControl.prototype.isPrototypeOf(ig_WebMenu.prototype))
			createMenu = true;
	}
	catch (e)
	{
		if (!ig_isMenuCreated)
			createMenu = true;
	}

	if (createMenu)
	{
		ig_WebMenu.prototype = new ig_WebControl();
		ig_WebMenu.prototype.constructor = ig_WebMenu;
		ig_WebMenu.prototype.base = ig_WebControl.prototype;

		ig_WebMenu.prototype.init = function(menuElement, menuProps)
		{
			this.MenuId = menuElement.id;
			this.MenuElement = menuElement;
			this.Id = menuElement.id;
			this.Element = menuElement;
			this.UniqueId = menuProps[0];
			this.MenuTarget = menuProps[1];
			this.WebMenuStyle = menuProps[2];
			this.HoverClass = menuProps[4];
			this.TopSelectedClass = menuProps[5];
			this.ExpandEffects = new igmenu_expandEffects(menuProps[8], menuProps[9], menuProps[10], menuProps[11], menuProps[12], menuProps[13], menuProps[14]);
			this.CheckedImage = menuProps[15];
			this.UncheckedImage = menuProps[16];
			this.DisabledClass = menuProps[17];
			this.DefaultItemClass = menuProps[18];
			this.ScrollImageTop = menuProps[19];
			this.ScrollImageTopDisabled = menuProps[20];
			this.ScrollImageBottom = menuProps[21];
			this.ScrollImageBottomDisabled = menuProps[22];
			this.LeftHandDisplay = menuProps[23];
			this.CurrentLeftHandDisplay = this.LeftHandDisplay
			this.HideDropDowns = menuProps[24];
			this.TargetUrl = menuProps[25];
			this.TargetFrame = menuProps[26];

			if (menuProps.length > 26)
			{
				this.MergeStyles = menuProps[27];
			}
			else
			{
				this.MergeStyles = false;
			}

			if (menuProps.length > 27)
			{
				this.HeaderClass = menuProps[28];
			}

			if (menuProps.length > 29)
				this._focusOnHover = menuProps[30];
			else
				this._focusOnHover = false;

			/* D.M. BR21320 12/7/2007 - Added a prop on the client that could be used to determine
			whether Section 508 compliance is enabled. */
			if (menuProps.length > 30)
				this._isSection508Compliant = menuProps[31];
			else
				this._isSection508Compliant = false;


			var uniqueId = this.getClientUniqueId();
			this.Events = new igmenu_events(eval("igmenu_" + uniqueId + "_Events"));
			this.MenuLoaded = false;
			this.NeedPostBack = false;
			this.CancelPostBack = false;
			this.TopHoverStarted = false;

			this.__activeItem = null;
			this._lastScrollX = 0;
			this._lastScrollY = 0;

		}
		ig_WebMenu.prototype.isHorizontal = function()
		{
			return (this.MenuTarget == 1);
		}
		ig_WebMenu.prototype.isVertical = function()
		{
			return (this.MenuTarget == 2);
		}
		ig_WebMenu.prototype.isPopup = function()
		{
			return (this.MenuTarget == 3);
		}
		ig_WebMenu.prototype.isWebStandard = function()
		{
			return (this.WebMenuStyle == 1);
		}
		ig_WebMenu.prototype.isRichClient = function()
		{
			return (this.WebMenuStyle == 2);
		}
		ig_WebMenu.prototype.isXPClient = function()
		{
			return (this.WebMenuStyle == 3);
		}
		ig_WebMenu.prototype.isDrillDown = function()
		{
			return (this.WebMenuStyle == 4);
		}

		ig_WebMenu.prototype.getItems = function()
		{
			var itemAr = new Array();
			var rows, cells, index = 0;
			/*D.M. 1/2/2007
			Modified the following segement to accomodate the addition of an extra row
			in the table that contains the menu items.  If it's a popup menu the extra row does
			not get rendered, otherwise we need to make sure we don't count the last row when looping
			through menu items.
			*/
			if (this.isPopup())
			{
				if (this.Element.childNodes[1].firstChild == null)
					rows = this.Element.firstChild.firstChild.rows;
				else
					rows = this.Element.childNodes[1].firstChild.rows;

				for (var r = 0; r < rows.length; r++)
				{
					cells = rows[r].cells;
					for (var i = 0; i < cells.length; i++)
						itemAr[index++] = igmenu_getItemById(cells[i].firstChild.id);
				}
			}
			else
			{
				rows = this.Element.rows;
				for (var r = 0; r < rows.length - 1; r++)
				{
					cells = rows[r].cells;
					for (var i = 0; i < cells.length; i++)
						itemAr[index++] = igmenu_getItemById(cells[i].firstChild.id);
				}
			}
			return itemAr;
		}

		// private
		ig_WebMenu.prototype.getClientUniqueId = function()
		{
			var u = this.UniqueId.replace(/:/gi, "");
			while (u.indexOf("$") != -1)
				u = u.replace("$", ""); // CLR 2.0

			u = u.replace(/_/gi, "");
			u = u.replace(/\-/gi, "");
			if (u.indexOf("{") != -1)
			{
				u = "IG" + u;
				u = u.replace(/\{/gi, "");
				u = u.replace(/\}/gi, "");
			}
			return u;
		}

		// private - Fires an event to client-side script and then to the server if necessary
		ig_WebMenu.prototype.fireEvent = function(eventObj, eventString)
		{
			var result = false;
			if (eventObj[0] != "")
				result = eval(eventObj[0] + eventString);
			if (this.MenuLoaded && result != true && eventObj[1] == 1 && !this.CancelPostBack)
				this.NeedPostBack = true;
			this.CancelPostBack = false;
			return result;
		}

		ig_WebMenu.prototype.getFirstEnabledItem = function()
		{
			var oItem = null;
			var oItems = this.getItems();
			for (var iCount = 0; oItems && iCount < oItems.length; iCount++)
			{
				oItem = oItems[iCount];
				if (oItem.getEnabled())
					return oItem;
			}
			return null;
		}

		ig_WebMenu.prototype.initEventHandlers = function(oSubMenu, oItem)
		{
			if (!oSubMenu._events)
			{
				if (!oItem && this.isPopup())
					return;
				else
				{
					var oItems = oItem.getItems();
					igmenu_initHandlers(oItem.WebMenu, oItems);
					oSubMenu._events = true;
					if (oSubMenu.element._old)
						return;
					oSubMenu.element._old = true;
					ig_shared.addEventListener(oSubMenu.element, "mouseover", igmenu_submenumouseover, true);
					ig_shared.addEventListener(oSubMenu.element, "mouseout", igmenu_submenumouseout, true);
				}
			}
		}

		// private - gets the scrollTop of page.
		ig_WebMenu.prototype.getScrollTop = function()
		{
			var ScrollTop = document.body.scrollTop;
			if (ScrollTop == 0)
			{
				if (window.pageYOffset)
					ScrollTop = window.pageYOffset;
				else
					ScrollTop = (document.body.parentElement) ? document.body.parentElement.scrollTop : 0;
			}
			return ScrollTop;
		}


		// private - gets the scrollLeft of page.
		ig_WebMenu.prototype.getScrollLeft = function()
		{
			var ScrollLeft = document.body.scrollLeft;
			if (ScrollLeft == 0)
			{
				if (window.pageXOffset)
					ScrollLeft = window.pageXOffset;
				else
					ScrollLeft = (document.body.parentElement) ? document.body.parentElement.scrollLeft : 0;
			}
			return ScrollLeft;
		}

		// private - clears all submenus from display
		ig_WebMenu.prototype.hideSubMenus = function()
		{
			/* D.M. 11/11/2008 - Bug 9406  */
			this._lastScrollX = this.getScrollLeft();
			this._lastScrollY = this.getScrollTop();

			if (igmenu_displaySubMenuTimerId)
				clearInterval(igmenu_displaySubMenuTimerId);
			this.CurrentLeftHandDisplay = this.LeftHandDisplay;
			this.igCurrentChild = null;

			if (this._oRootSubMenu)
				this._oRootSubMenu.dismiss();
			var oSubMenuMain = igmenu_getSubMenuById(this, this.Element.id);
			oHoveredItem = oSubMenuMain.getHoveredItem();
			if (oHoveredItem)
				oHoveredItem.unhover();
		}

		// private - cancels all animations in progress
		ig_WebMenu.prototype.cancelAnimations = function()
		{
			if (this._oRootSubMenu)
				this._oRootSubMenu.cancelAnimation();
		}

		// private - Hides the menu if it is displayed as a popup
		ig_WebMenu.prototype.dismiss = function()
		{
			ig_inMenu = false;
			igmenu_pageMouseDown();
		}

		// private - returns the tabIndex of the webMenu
		ig_WebMenu.prototype.getTabIndex = function()
		{
			return this.Element.tabIndex;
		}

		// private - Update internal buffer for items that are checked on or off
		ig_WebMenu.prototype.updateItemCheck = function(itemId, bChecked)
		{
			var formControl = igmenu_getElementById(this.UniqueId);
			if (formControl == null)
				return;
			var menuState = formControl.value;
			var newValue;
			var oldValue;
			if (bChecked)
			{
				oldValue = "0"; newValue = "1";
			}
			else
			{
				oldValue = "1"; newValue = "0";
			}
			var oldString = itemId + ":Chck=" + oldValue + "<%;";
			var newString = itemId + ":Chck=" + newValue + "<%;";
			if (menuState.search(oldString) >= 0)
				menuState = menuState.replace(oldString, newString);
			else
			{
				oldString = itemId + ":Chck=" + newValue + "<%;";
				if (menuState.search(oldString) >= 0)
				{
					menuState = menuState.replace(oldString, newString);
				}
				else
					menuState += newString;
			}
			formControl.value = menuState;
		}


		ig_WebMenu.prototype.initSubMenuRoot = function(oSubMenu)
		{
			this.hideSubMenus();
			if (!oSubMenu)
				return;
			ig_oCurrentSubMenu = oSubMenu;
			ig_oActiveMenu = this;
			this._oRootSubMenu = oSubMenu;
			this._oActiveSubMenu = oSubMenu;
		}
	}
	/*VS 11/20/2006 move submenu containers to body */
	ig_WebMenu.prototype._move = function()
	{
		if (this._abs)
			return;
		this._abs = new Array(); /* storage of moved elements */
		var elem = igmenu_getElementById("abs_" + this.MenuName);
		if (!elem)
			return;
		var nodes = elem.childNodes, body = document.body;
		var i = nodes ? nodes.length : 0;
		while (i-- > 0)
		{
			/* D.M. BR24079 6/22/07 - No need to call elem.removeChild(this._abs[i] = nodes[i]);
			* here, the insert will remove the node for us. */
			this._abs[i] = nodes[i];
			body.insertBefore(this._abs[i], body.firstChild);
		}
		if (elem)
			elem.parentNode.removeChild(elem);
	}
	/*BR23107*/
	ig_isMenuCreated = true;
	return new ig_WebMenu(menuElement, props);
}

function ig_WebMenu(menuElement, props)
{
	if (arguments.length != 0)
		this.init(menuElement, props);
}

// private - event initialization for menu object
function igmenu_events(events)
{
	this.InitializeMenu = events[0];
	this.ItemCheck = events[1];
	this.ItemClick = events[2];
	this.SubMenuDisplay = events[3];
	this.ItemHover = events[4];
}

// private - event initialization for menu object
function igmenu_expandEffects(a, b, c, d, e, f, g)
{
	this.Duration = a;
	this.Opacity = b;
	this.Type = c;
	this.ShadowColor = d;
	this.ShadowWidth = e;
	this.Delay = f;
	this.RemovalDelay = g;
}

// private - obtains the row element associated with the event
function ig_fromEvent(evnt)
{
	var item;
	if (ig_csom.IsNetscape6)
	{
		item = evnt.target;
	}
	else
		item = evnt.srcElement;
	return ig_fromItem(item);
}

// private 
function ig_fromItem(eItem)
{
	while (eItem.tagName != "TABLE")
	{
		/*D.M. BR22622 5/7/07 - It is possible for the click event to be triggered by an element outside of
		the menu, when this happens eItem will eventually become the HTML element, at which point eItem.parentNode
		becomes undefined.
		*/
		if (eItem == null || eItem.parentNode == undefined)
			return null;
		eItem = eItem.parentNode;
	}
	return eItem;
}

// private
function igmenu_getSubMenu(eItem)
{
	submenu = false;
	while (!submenu)
	{
		if (eItem.getAttribute("submenu") == '1')
			submenu = true;
		else
			eItem = eItem.parentNode;
	}
	return eItem;
}

// private
function igmenu_getRightPos(e)
{
	var x = e.offsetRight;
	var tmpE = e.offsetParent;
	while (tmpE != null)
	{
		x += tmpE.offsetRight;
		tmpE = tmpE.offsetParent;
	}
	return x;
}
// private
function igmenu_getLeftPos(element)
{
	var x = 0;
	var parent = element;
	while (parent != null)
	{
		x += parent.offsetLeft;
		parent = parent.offsetParent;
	}
	return x;
}
// private
function igmenu_getTopPos(element)
{
	var y = 0;
	var parent = element;
	while (parent != null)
	{
		y += parent.offsetTop;
		parent = parent.offsetParent;
	}
	return y;
}

var clearCurrentMenu = true;
// private - Clears submenus at timer expiration
function clearTimerExpired()
{
	if (clearCurrentMenu && ig_oActiveMenu != null)
	{
		ig_oActiveMenu.hideSubMenus();
		clearTimeout(igmenu_displayMenuTimerId);
	}
}

// private - Handles the mouse down event
function igmenu_mousedown(evnt)
{
	if (evnt == null)
		evnt = window.event;
	var eItem = ig_fromEvent(evnt);
	if (eItem != null)
	{
		ig_inMenu = true;
		var igDisabled = eItem.getAttribute("igDisabled");
		if (igDisabled != null && igDisabled.length > 0)
		{
			return;
		}
	}
	else
		return;
	var oMenu = igmenu_getMenuByItemId(eItem.id);
	var oItem = igmenu_getItemById(eItem.id);
	if (oMenu == null || oMenu.MenuLoaded == false)
		return;

	if (oMenu.isHorizontal() && (oMenu.isRichClient() || oMenu.isXPClient()) && oItem.isTopLevelItem())
	{
		var childId = oItem.getChildSubMenuId();
		if (childId != null && childId.length > 0)
		{
			var currentChildId = igmenu_getSubMenu(eItem).igCurrentChildId;
			//if(childId != null && childId.length > 0 && childId == currentChildId) {
			//	oMenu.hideSubMenus();
			//	ig_startClick=false;
			//	oMenu.TopHoverStarted = false;
			//	oItem.hover();
			//	return;
			//}
			var oldClass = eItem.igClass;
			eItem.setAttribute("igPrevClass", oldClass);
			clearTimeout(igmenu_displayMenuTimerId);
			oMenu.TopHoverStarted = true;
			oItem._hovered = false;
			oItem.hover();
			var oSubMenu = oItem.getChildSubMenu();
			oSubMenu.show(oItem);
			igmenu_getSubMenu(eItem).igCurrentChildId = childId;

			/* SJZ 2/28/08 BR30681 - Note sure where item is supposed to becomign from, but igurrentItem is never used, so i 
			* believe it is safe to remove this code 
			igmenu_getSubMenu(eItem).igCurrentItem = item.id;*/
			return;
		}
	}
	if (oItem.getChildSubMenuId() == null)
		oMenu.TopHoverStarted = false;
	ig_startClick = true;
	ig_cancelEvent(evnt);
}

var ig_startClick = false;

/* SJZ 10/12/07 BR27176 - On the server, igUrl is being encoded, so now on the client we need to unescape it. 
* i've also included additional checks for the javascript variable. This is doen b/c we want to make sure that 
* a developer can specify any type of string for example 
* TargetUrl="javascript:alert(&quot;ABC&quot;);" or  TargetUrl="javascript:alert(\"ABC\");" or TargetUrl="javascript:alert('\"ABC\"');"
* prior to this fix, the user could only specify TargetUrl="javascript:alert('ABC');", which isn't as forgiving or flexible.*/
function __igmenu_navigateUrl(igUrl, igFrame)
{
	var url = unescape(igUrl);
	var index = url.indexOf("javascript:");
	/* 7/17/2009 In order to eval javascript expression, the "javascript:" should be at index 0, not larget than 0! 
	 * if we detect larger than 0 index for "javascript:" the evaluation will break the JS with exception / error  
	 */
	if (index == 0)
	{
		url = eval(igUrl);
		/* AS 7/17/2009 Let's return after we eval the expression, b/c ig.navigateUrl will eval it again if we let that call! */
		return;
    }
    /* AS 7/17/2009 then leave the ESCAPED url for navigation ! */
	ig.navigateUrl(igUrl, igFrame);
	return;
}


// private - Handles the mouse up event
function igmenu_mouseup(evnt, eItemElement)
{
	var eItem = null;
	if (evnt == null)
		evnt = window.event;
	if (!eItemElement)
		eItem = ig_fromEvent(evnt);
	else
		eItem = ig_fromItem(eItemElement);

	if (eItem == null) { return; }

	var oMenu = igmenu_getMenuByItemId(eItem.id);
	var oItem = igmenu_getItemById(eItem.id);
	if (oMenu == null)
	{
		return;
	}
	var topLevel = oItem.isTopLevelItem();
	var oSubMenu = oItem.getChildSubMenu();
	var igUrl = oItem.getTargetUrl();

	if (ig_csom.IsIE && evnt != null)
		evnt.cancelBubble = true;
	if (!oItem.isEnabled())
		return;

	if (oItem.isSeparator())
	{
		clearCurrentMenu = false;
		return;
	}

	if (oSubMenu)
	{
		if (igUrl == null || igUrl.length == 0)
		{
			oMenu.fireEvent(oMenu.Events.ItemClick, "(\"" + oMenu.MenuName + "\",\"" + eItem.id + "\")");
			if (oMenu.NeedPostBack && (oMenu.isWebStandard() || ((oMenu.isRichClient() || oMenu.isXPClient()) && !topLevel)))
				__doPostBack(oMenu.UniqueId, eItem.id + ":MenuClick");
			return;
		}
	}

	if (ig_startClick == true)
	{
		if (!oMenu.isDrillDown())
			oMenu.hideSubMenus();
		var checked = eItem.getAttribute("igChk");
		var checkbox = eItem.getAttribute("igChkBx");
		if (ig.notEmpty(checkbox))
		{
			var bCheck = (checked != null) && (checked == '0');
			var postCommand = "";
			if (oMenu.fireEvent(oMenu.Events.ItemCheck, "(\"" + oMenu.MenuName + "\",\"" + eItem.id + "\"," + bCheck + ")"))
				return;

			var checkElement = oItem.getCheckBoxElement();
			/*D.M. BR21947 4/12/07 added Section508 support for checkbox images under enhanced rendering. */
			var alt = checkElement.getAttribute("alt");
			var newAlt = "";
			if (alt == null)
				alt = checkElement.getAttribute("title");
			if (alt != null)
			{
				newAlt = checkElement.getAttribute("igAltCk");
				/* D.M. BR24366 7/2/2007 - If newAlt is null set it to "" so that no alt text is displayed.*/
				if (newAlt == null)
					newAlt = "";
				checkElement.setAttribute("igAltCk", alt);
			}
			if (checked != null && checked == "1")
			{
				bCheck = false;
				postCommand = ":Uncheck";
				if (checkElement.tagName == "IMG")
				{
					checkElement.src = oMenu.UncheckedImage;
					checkElement.alt = newAlt;
				}
				else
				{
					if (checkElement.tagName == "SPAN")
					{
						checkElement.innerHTML = "";
						checkElement.title = newAlt;
					}
				}
				eItem.setAttribute("igChk", "0");
			}
			else
			{
				if (checkElement.tagName == "IMG")
				{
					checkElement.src = oMenu.CheckedImage;
					checkElement.alt = newAlt;
				}
				else
					if (checkElement.tagName == "SPAN")
				{
					if (ig_csom.IsIE)
						checkElement.innerHTML = "a";
					else
						checkElement.innerHTML = "*";
				}
				bCheck = true;
				postCommand = ":Check";
				eItem.setAttribute("igChk", "1");
			}

			if (oMenu.NeedPostBack)
			{
				__doPostBack(oMenu.UniqueId, eItem.id + postCommand);
			}
			oMenu.updateItemCheck(eItem.id, bCheck);
			ig_startClick = false;
			if (ig_menuPopup != null)
			{
				var oSubMenu = igmenu_getSubMenuById(oMenu, ig_menuPopup.id);
				oSubMenu.dismiss();
				ig_menuPopup = null;
			}
			var igFrame = eItem.getAttribute("igFrame");
			/* SJZ 10/12/07 BR27176 - see the definition for __igmenu_navigateUrl*/
			if (igUrl != null)
				this.__igmenu_navigateUrl(igUrl, igFrame);
			oItem.hover();
			return;
		}
		if (oMenu.fireEvent(oMenu.Events.ItemClick, "(\"" + oMenu.MenuName + "\",\"" + eItem.id + "\")"))
			return;

		if (!oMenu.isDrillDown() && evnt != null)
			igmenu_mouseout(evnt);

		igmenu_getSubMenu(eItem).igCurrentChild = null;
		if (ig_menuPopup != null)
		{
			var oSubMenu = igmenu_getSubMenuById(oMenu, ig_menuPopup.id);
			oSubMenu.dismiss();
			ig_menuPopup = null;
		}
		ig_startClick = false;
		var igFrame = eItem.getAttribute("igFrame");
		igUrl = oItem.getTargetUrl();
		if (igUrl != null)
		{
			/* SJZ 10/12/07 BR27176 - see the definition for __igmenu_navigateUrl*/
			/* RCS 02/20/2008 BRBR29540 - "this" was incorrectly pointing to Html elements */
			__igmenu_navigateUrl(igUrl, igFrame);
			return;
		}
		if (oMenu.NeedPostBack)
		{
			__doPostBack(oMenu.UniqueId, eItem.id + ":MenuClick");
			return;
		}
	}
}

var ig_inMenu = false;
var ig_MouseX;
var ig_MouseY;
// private - Handles the global mouse down event
function igmenu_pageMouseDown(evnt)
{
	if (evnt != null)
	{
		ig_MouseX = evnt.clientX;
		ig_MouseY = evnt.clientY;
	}
	if (ig_inMenu == true)
		return;
	ig_startClick = false;
	ig_inMenu = false;
	if (ig_oActiveMenu != null)
	{
		ig_oActiveMenu.TopHoverStarted = false;
		ig_oActiveMenu.hideSubMenus();
	}
	if (ig_menuPopup != null)
	{
		var oSubMenu = igmenu_getSubMenuById(ig_oActiveMenu, ig_menuPopup.id);
		oSubMenu.dismiss();
		ig_menuPopup = null;
	}
}

// private - Handles mouse selection for the menu
function igmenu_selectStart(evnt)
{
	if (evnt == null)
		evnt = window.event;
	ig_cancelEvent(evnt);
	return false;
}

// private - Displays a popup menu in the appropriate position
function igmenu_showMenu(name, evnt, x, y)
{
	if (ig_menuPopup != null)
	{
		if (ig_oActiveMenu)
		{
			ig_oActiveMenu.hideSubMenus();
			var oSubMenu = igmenu_getSubMenuById(ig_oActiveMenu, ig_menuPopup.id);
			oSubMenu.dismiss();
			//ig_oActiveMenu.hideSubMenu(ig_menuPopup);
		}
		ig_menuPopup = null;
	}
	var eItem = igmenu_getElementById(name + "_MainM");
	if (eItem == null)
	{
		alert("Popup menu name is not valid")
		return;
	}
	var oMenu = igmenu_getMenuById(name);
	if (oMenu == null)
		return;

	var oSubMenu = igmenu_getSubMenuById(oMenu, name + "_MainM");
	if (evnt == null)
	{
		if (ig_csom.IsIE)
			evnt = window.event;
		else
			evnt = window.Event;
	}
	if (eItem != null)
	{
		if (x && y)
		{
			/* donp UXG PRB0233 6/29/07 */
			/* D.M. BR25146 8/21/2007 - Don't want to call indexOf on an int */
			if (x.toString().indexOf("px") == -1)
				x += "px";
			eItem.parentNode.style.left = x;

			if (y.toString().indexOf("px") == -1)
				y += "px";
			eItem.parentNode.style.top = y;
		}
		else
		{
			if (ig_csom.IsIE)
			{

				y = evnt.y - 2 + document.body.scrollTop + document.body.parentNode.scrollTop;
				x = evnt.x - 2 + document.body.scrollLeft + document.body.parentNode.scrollLeft;
			}
			else
			{
				y = ig_MouseY - 2 + document.body.scrollTop + document.body.parentNode.scrollTop;
				x = ig_MouseX - 2 + document.body.scrollLeft + document.body.parentNode.scrollLeft;
			}
			var src = ig_csom.getSourceElement(evnt);
			if (src)
			{
				var parent = src;
				var tmpX = x;
				var tmpY = y;
				var sets = false;
				while (parent != null && parent.tagName != "BODY")
				{
					if (parent.style.position == "relative")
					{
						sets = true;
						tmpX = 0;
						tmpY = 0;
					}
					tmpX += parent.offsetLeft;
					tmpY += parent.offsetTop;

					parent = parent.offsetParent;
				}
				if (sets && ig_csom.IsIE)
				{//D.M. 2/27/07 BR19449 Skip this if you're firefox.
					x += tmpX;
					y += tmpY;
				}
			}
			var parent = eItem;
			while (parent != null)
			{
				if (parent.style.position == "absolute")
				{
					if (parent.offsetParent == null)
						break;
					x -= parent.offsetParent.offsetLeft;
					y -= parent.offsetParent.offsetTop;
					break;
				}
				parent = parent.offsetParent;
			}

			eItem.parentNode.style.top = y.toString() + "px";
			eItem.parentNode.style.left = x.toString() + "px";
		}
		ig_menuPopup = eItem;

		oSubMenu.___display(null, true);
		oSubMenu._visible = true;
		ig_menuPopup.menuObject = oMenu;
		ig_oActiveMenu = oMenu;
	}
}

// private - Initializes an Item object with properties and method references
function ig_CreateMenuItem(eItem)
{
	/* D.M. BR23107 6/6/07  - We have to do this because Safari lacks support for the
	isPrototypeOf method.  This way if the method fails we fall through and use
	flags instead. */
	var createItem = false;
	try
	{
		if (!ig_WebUIElement.prototype.isPrototypeOf(ig_MenuItem.prototype))
			createItem = true;
	}
	catch (e)
	{
		if (!ig_isMenuItemCreated)
			createItem = true;
	}

	if (createItem)
	{
		ig_MenuItem.prototype = new ig_WebUIElement();

		ig_SubMenu.prototype.getOwnerItem = function()
		{
			return (this._ownerItem);
		}

		ig_MenuItem.prototype.getElement = function()
		{
			return this.element;
		}

		ig_MenuItem.prototype.getMenuId = function()
		{
			var menuName = this.element.id;
			var strArray = menuName.split("_");
			menuName = strArray[0];
			return menuName;
		}

		ig_MenuItem.prototype.__displaySubMenu = function(oChildSubMenu)
		{
			clearTimeout(igmenu_clearMenuTimerId);
			var callback = igmenu_createCallback(this.__display, this, oChildSubMenu);
			igmenu_displayMenuTimerId = setTimeout(callback, this.WebMenu.ExpandEffects.Delay);
		}

		ig_MenuItem.prototype.__display = function(oChildSubMenu)
		{
			oChildSubMenu.show(this);
		}

		ig_MenuItem.prototype._getTextElement = function()
		{
			/* SJZ 10/12/07 BR27104 - apparently, in firefox the child with the text isn't always located
			* at index 1. So i modified the logic so that it loops through children to find element with the text.
			* var i = 1;
			* if(ig_csom.IsIE)
			*	i = 0;
			* if(this.WebMenu.isHorizontal() && this.isTopLevelItem())
			*	return this.element.rows[0].cells[1].childNodes[0];
			* else
			*	return this.element.rows[0].cells[1].childNodes[i];*/

			if (this.WebMenu.isHorizontal() && this.isTopLevelItem())
				return this.element.rows[0].cells[1].childNodes[0];
			else
			{
				var i = 0;
				var child = this.element.rows[0].cells[1].childNodes[0];
				while (child == null || !child.getAttribute)
					child = this.element.rows[0].cells[1].childNodes[i++];
				return child;
			}
		}

		ig_MenuItem.prototype.getText = function()
		{
			var element = this._getTextElement();
			var text = element.innerHTML;
			text = text.replace("<U>", "");
			text = text.replace("</U>", "");
			text = text.replace("<u>", "");
			text = text.replace("</u>", "");
			text = text.replace(/&amp;/g, "&");
			return text;
		}

		ig_MenuItem.prototype.setText = function(text)
		{
			var element = this._getTextElement();
			element.innerHTML = text;
		}

		ig_MenuItem.prototype.isSeparator = function()
		{
			var igSeparator = this.element.getAttribute("igSep");
			return (igSeparator != null && igSeparator.length > 0) ? true : false;
		}

		ig_MenuItem.prototype.isTopLevelItem = function()
		{
			var igTop = this.element.getAttribute("igTop");
			return (igTop != null && igTop.length > 0) ? true : false;
		}

		ig_MenuItem.prototype.isEnabled = function()
		{
			return this.getEnabled();
		}

		ig_MenuItem.prototype.getSelected = function()
		{
			return this._selected;
		}
		ig_MenuItem.prototype.setSelected = function(bSelected)
		{
			this._selected = bSelected;
		}

		ig_MenuItem.prototype.getOwnerSubMenu = function()
		{
			var eSubMenu = this.element;
			while (true)
			{
				if (eSubMenu.getAttribute("submenu") == '1')
				{
					return igmenu_getSubMenuById(this.WebMenu, eSubMenu.id);
				}
				else
					eSubMenu = eSubMenu.parentNode;
			}
			return null;
		}

		ig_MenuItem.prototype.getChildSubMenuId = function()
		{
			var submenuId = this.element.getAttribute("igChildId");
			if (ig.isEmpty(submenuId))
				return null;
			else
				return submenuId;
		}

		ig_MenuItem.prototype.getChildSubMenu = function()
		{
			var submenuId = this.getChildSubMenuId();
			if (submenuId != null)
			{
				var oSub = igmenu_submenuArray[submenuId];
				if (oSub)
					return oSub;
				var eSub = igmenu_getElementById(submenuId);
				if (!eSub)
					return null;
				oSub = ig_CreateSubMenu(this.WebMenu, eSub);
				igmenu_submenuArray[submenuId] = oSub;
				oSub.setOwnerItem(this);
				return oSub;
			}
			return null;
		}

		ig_MenuItem.prototype.getTag = function()
		{
			var igTag = this.element.getAttribute("igTag");
			return (igTag != null && igTag.length > 0) ? igTag : null;
		}
		ig_MenuItem.prototype.setTag = function(text)
		{
			this.element.setAttribute("igTag", text);
		}
		ig_MenuItem.prototype.getHoverClass = function()
		{
			return this.element.getAttribute("igHov")
		}
		ig_MenuItem.prototype.setHoverClass = function(hoverClass)
		{
			this.element.setAttribute("igHov", hoverClass)
		}
		ig_MenuItem.prototype.getEnabled = function()
		{
			if (this.element != null)
			{
				/*D.M. 4/17/2007 BR22114 - When getEnabled is called on a top level menu item when the enabled
				property of the menu has been set to false this.element.getAttribute("igDisabled")
				returns null.  We can ignore this case for IE (for now), since getEnabled would never be called
				in this situation.  When the menu is rendered for FX we need to manually determine if
				the parent table has been disabled.
				*/
				if (ig_csom.IsFireFox && this.element.getAttribute("igDisabled") == null)
				{
					return (this.WebMenu.Element.hasAttribute("disabled") ? false : true)
				}
				else
					return (this.element.getAttribute("igDisabled") ? false : true);
			}
		}

		ig_MenuItem.prototype.setEnabled = function(enabled)
		{
			var oMenu = this.WebMenu;
			if (enabled == true)
			{
				if (this.isEnabled())
					return;
				this.element.removeAttribute("igDisabled");
				var oldClass = this.element.getAttribute("oldEnabledClass");
				if (oldClass == null && oMenu.DefaultItemClass != null)
					this.element.className = oMenu.DefaultItemClass;
				else
					this.element.className = oldClass;
				this.element.removeAttribute("oldEnabledClass");
			}
			else
			{
				if (!this.isEnabled())
					return;
				var disabledClass = oMenu.DisabledClass;
				this.element.setAttribute("igDisabled", "1");
				if (this.element.className != oMenu.HoverClass &&
					this.element.className != this.element.getAttribute("igHov"))
				{
					var oldClass = this.element.className;
					this.element.setAttribute("oldEnabledClass", oldClass);
				}
				this.element.className = disabledClass;
			}
		}

		ig_MenuItem.prototype.getTargetFrame = function()
		{
			var frame = this.element.getAttribute("igFrame");
			if (ig_csom.notEmpty(frame))
				return frame;
			else
				if (ig_csom.notEmpty(this.WebMenu.TargetFrame))
			{
				return this.WebMenu.TargetFrame;
			}
			else
				return null;
		}
		ig_MenuItem.prototype.setTargetFrame = function(frame)
		{
			this.element.setAttribute("igFrame", frame)
		}
		ig_MenuItem.prototype.getTargetUrl = function()
		{
			var url = this.element.getAttribute("igUrl");
			if (ig_csom.notEmpty(url))
				return url;
			else
				if (ig_csom.notEmpty(this.WebMenu.TargetUrl))
			{
				return this.WebMenu.TargetUrl;
			}
			else
				return null;
		}
		ig_MenuItem.prototype.setTargetUrl = function(url)
		{
			this.element.setAttribute("igUrl", url)
		}
		ig_MenuItem.prototype.getNextSibling = function()
		{
			var e = this.element.parentNode;
			var attr = e.getAttribute("igitem");
			while (attr == null || attr.length == 0)
			{
				e = e.parentNode;
				attr = e.getAttribute("igitem");
			}

			e = e.nextSibling;
			while (e && e.tagName != "TR" && e.tagName != "TD")
				e = e.nextSibling;
			var item = null;
			if (e)
			{
				if (e.style.display == "none")
					return;
				if (e.tagName == "TR")
					item = igmenu_getItemById(e.firstChild.firstChild.id);
				if (e.tagName == "TD")
					item = igmenu_getItemById(e.firstChild.id);
			}
			return item;
		}
		ig_MenuItem.prototype.getPrevSibling = function()
		{
			var e = this.element.parentNode;
			var attr = e.getAttribute("igitem");
			while (attr == null || attr.length == 0)
			{
				e = e.parentNode;
				attr = e.getAttribute("igitem");
			}
			e = e.previousSibling;
			while (e && e.tagName != "TR" && e.tagName != "TD")
				e = e.previousSibling;
			var item = null;
			if (e)
			{
				if (e.tagName == "TR")
					item = igmenu_getItemById(e.firstChild.firstChild.id);
				if (e.tagName == "TD")
					item = igmenu_getItemById(e.firstChild.id);
			}
			return item;
		}

		ig_MenuItem.prototype.getFirstChild = function()
		{
			var item = null;
			item = igmenu_getItemById(this.element.id + "_1");
			if (item == null)
			{
				if (this.getChildSubMenuId())
				{
					var index = 2;
					while (item == null && index < 100)
					{
						item = igmenu_getItemById(this.element.id + "_" + index);
						index++
					}
				}
			}
			return item;
		}
		ig_MenuItem.prototype.getParent = function()
		{
			var item = null;
			if (this.getLevel() == 0)
				return null;
			var itemName = this.element.id.split("_")
			if (itemName.length > 1)
			{
				var parentName = this.element.id.substr(0, this.element.id.length - itemName[itemName.length - 1].length - 1);
				item = igmenu_getItemById(parentName);
			}
			return item;
		}
		ig_MenuItem.prototype.getItems = function()
		{
			var itemAr = new Array();
			var itemCount = 0;
			var item = this.getFirstChild();
			while (item)
			{
				itemAr[itemCount++] = item;
				item = item.getNextSibling();
			}
			return itemAr;
		}
		ig_MenuItem.prototype.getChecked = function()
		{
			var item = this.element;
			var checked = item.getAttribute("igChk");
			var checkbox = item.getAttribute("igChkBx");
			if (checkbox != null && checkbox.length > 0)
				if (checked != null && checked.length > 0 && checked == '1')
				return true;
			return false;
		}
		ig_MenuItem.prototype.setChecked = function(bChecked)
		{
			var ms = igmenu_getMenuByItemId(this.element.id);
			var item = this.element;
			var checkbox = item.getAttribute("igChkBx");
			if (checkbox == null || checkbox.length == 0)
				return;

			var topItem = item.getAttribute("igTop");
			var checkElement = this.getCheckBoxElement();

			if (!bChecked)
			{
				if (checkElement.tagName == "IMG")
					checkElement.src = ms.UncheckedImage;
				else
					if (checkElement.tagName == "SPAN")
					checkElement.innerHTML = "";
				item.setAttribute("igChk", "0");
			}
			else
			{
				if (checkElement.tagName == "IMG")
					checkElement.src = ms.CheckedImage;
				else
					if (checkElement.tagName == "SPAN")
				{
					if (ig_csom.IsIE)
						checkElement.innerHTML = "a";
					else
						checkElement.innerHTML = "*";
				}
				item.setAttribute("igChk", "1");
			}
			ms.updateItemCheck(this.element.id, bChecked);
		}

		ig_MenuItem.prototype.getCheckBoxElement = function()
		{
			if (this.WebMenu.isHorizontal() && this.isTopLevelItem())
				return this.element.rows[0].cells[0].firstChild;
			else
				return this.element.rows[0].cells[0].firstChild;
		}

		ig_MenuItem.prototype.focus = function()
		{
			this.element.hideFocus = true;
			try
			{
				this.element.focus();
			}
			catch (e)
			{
				//debugger;
				//alert( "focus exception");
			}

		}

		ig_MenuItem.prototype.getAccessKey = function()
		{
			if (this.element.tagName == "TR")
			{
				var i = 0;
				var td;
				if (ig_csom.IsIE)
					td = this.element.childNodes[0];
				else
					td = this.element.childNodes[1];
				while (td.childNodes[i] != null)
				{
					if (td.childNodes[i].tagName == "DIV")
					{
						return td.accessKey;
					}
					i++;
				}
				return "";
			}
			else
				return this.element.accessKey;
		}

		ig_MenuItem.prototype.activate = function()
		{
			var igFrame = this.element.getAttribute("igFrame");
			var igUrl = this.element.getAttribute("igUrl");

			if (igUrl != null)
			{
				/* SJZ 10/12/07 BR27176 - see the definition for __igmenu_navigateUrl*/
				/* RCS 02/20/2008 BRBR29540 - "this" was incorrectly pointing to Html elements */
				__igmenu_navigateUrl(igUrl, igFrame);
				return;
			}
			ig_startClick = true;
			igmenu_mouseup(null, this.element);
		}

		ig_MenuItem.prototype.getLevel = function()
		{
			var itemName = this.element.id.split("_")
			if (itemName.length > 1)
			{
				return itemName.length - 2;
			}
		}
		ig_MenuItem.prototype.getIndex = function()
		{
			var index = 0;
			var itemName = this.element.id.split("_");
			if (itemName.length > 1)
			{
				index = parseInt(itemName[itemName.length - 1]);
				return index - 1;
			}
		}
		// private - displays menu item using the hover styles
		ig_MenuItem.prototype.hover = function()
		{

			if (this._hovered)
			{
				this.focus();
				return;
			}
			this._hovered = true;

			this.Element.tabIndex = this.WebMenu.Element.tabIndex;

			var oOwnerSubMenu = this.getOwnerSubMenu();
			var oHoverItem = oOwnerSubMenu.getHoveredItem();
			if (oHoverItem && oHoverItem != this)
				oHoverItem.unhover();
			oOwnerSubMenu.setHoveredItem(this);


			if (!this.isEnabled())
				return;
			var oMenu = this.WebMenu;


			oMenu.__activeItem = this;

			var hoverClass = this.element.getAttribute("igHov");
			clearCurrentMenu = false;
			if (oMenu.fireEvent(oMenu.Events.ItemHover, "(\"" + oMenu.MenuName + "\",\"" + this.element.id + "\", true)"))
				return;
			if (hoverClass == null || hoverClass.length == 0)
			{
				hoverClass = oMenu.HoverClass;
			}

			this.__offsetLeft = null;
			if (ig_csom.IsIE && this.getLevel() > 0)
			{
				this.__offsetLeft = this.element.cells[2].offsetLeft;
			}

			var mergeStyles = oMenu.MergeStyles;
			if (this.isTopLevelItem() && (oMenu.isHorizontal() && (oMenu.isRichClient() || oMenu.isXPClient()) &&
				oMenu.TopHoverStarted) && oMenu.TopSelectedClass.length > 0)
			{
				hoverClass = oMenu.TopSelectedClass;
				var topHover = this.element.getAttribute("igHov");
				if (this.element.className != "TopHover" && this.element.className != hoverClass)
					this.element.igClass = this.element.className;
				if (!ig.isEmpty(hoverClass))
				{
					if (mergeStyles)
					{
						this.element.className += " " + hoverClass;
					}
					else
						this.element.className = hoverClass;
				}
			}
			else
			{
				if (!ig.isEmpty(this.element.className))
				{
					if (this.element.className.indexOf(hoverClass) != -1)
						return;
					this.element.igClass = this.element.className;
				}
				if (!ig.isEmpty(hoverClass))
				{
					if (mergeStyles)
						this.element.className += " " + hoverClass;
					else
						this.element.className = hoverClass;
				}
			}

			this.__offsetLeft = null;
			if (this.__offsetLeft != null)
			{
				var e = this.element.cells[2];
				if (e.firstChild && (e.offsetLeft != this.__offsetLeft))
				{
					e.firstChild.style.marginLeft = 1;
				}
			}
			/*D.M. BR25121*/
			if (this.WebMenu._isSection508Compliant || this.WebMenu._focusOnHover)
				this.focus();

			var oldhoverimage = this.element.getAttribute("igoldhovimage");
			var hoverimage = this.element.getAttribute("ighovimage");

			if (!ig.isEmpty(hoverimage))
			{
				var imgElem = this.getImageElement(eItem);
				if (imgElem != null)
				{
					/* D.M. BR25215 8/20/2007 - We need to use the old hover image if there is one
					so that we can revert to it in unhover.  Otherwise if a user hovers over an item
					and then clicks on it (causing hover to be called again) the hover image will replace
					the default image and the default image will be lost. */
					if (oldhoverimage != null)
						this.element.setAttribute("igoldhovimage", oldhoverimage);
					else
						this.element.setAttribute("igoldhovimage", imgElem.src);
					imgElem.src = hoverimage;
				}
			}
		}
		// private - displays the item using non-hover styles
		ig_MenuItem.prototype.unhover = function(bFireEvent)
		{
			var oMenu = this.WebMenu;

			oMenu.__activeItem = null;

			this.Element.tabIndex = 0;

			if (bFireEvent && oMenu.fireEvent(oMenu.Events.ItemHover, "(\"" + oMenu.MenuName + "\",\"" + this.element.id + "\", false)"))
				return;

			if (!this._hovered)
				return;

			if (!this.isEnabled())
				return;

			this._hovered = false;

			var prevClass = this.element.getAttribute("igPrevClass");
			if (prevClass == null)
			{
				if (this.element.igClass != null)
					this.element.className = this.element.igClass;
				else
					this.element.className = "";
			}
			else
			{
				this.element.className = prevClass;
			}

			if (this.__offsetLeft != null)
			{
				var e = this.element.cells[2];
				if (e.firstChild)
					e.firstChild.style.marginLeft = 0;
			}

			var hoverimage = this.element.getAttribute("igoldhovimage");
			if (hoverimage != null && hoverimage.length > 0)
			{
				var imgElem = this.getImageElement(this.element);
				if (imgElem != null)
				{
					imgElem.src = hoverimage;
				}
			}
			this.setSelected(false);
		}

		// private - obtain the element containing the item image tag
		ig_MenuItem.prototype.getImageElement = function()
		{
			var e = null;
			if (this.isTopLevelItem() && this.MenuTarget == 1)
				e = this.element.childNodes[0];
			else
				e = this.element.rows[0].cells[0].firstChild;
			if (e == null || e.tagName != "IMG")
				return null;
			return e;
		}
	}
	/*BR23107*/
	ig_isMenuItemCreated = true;
	return new ig_MenuItem(eItem);
}

function ig_MenuItem(eItem)
{
	this.element = eItem;
	this.Element = eItem;
	this.Id = eItem.id;
	this.WebMenu = igmenu_getMenuByItemId(this.Id);
	this._selected = false;
}

function igmenu_initHandlers(oMenu, oItems)
{
	for (var i = 0; i < oItems.length; i++)
	{
		var oItem = oItems[i];
		var eItem = oItem.Element;
		if (eItem._old)
			continue;
		eItem._old = true;
		ig_shared.addEventListener(eItem, "selectstart", igmenu_selectStart, true);
		if (oMenu.isDrillDown())
		{
			ig_shared.addEventListener(eItem, "mouseover", igmenu_podmouseover, true);
			ig_shared.addEventListener(eItem, "mouseout", igmenu_podmouseout, true);
			ig_shared.addEventListener(eItem, "mousedown", igmenu_podmousedown, true);
			ig_shared.addEventListener(eItem, "mouseup", igmenu_podmouseup, true);
			ig_shared.addEventListener(eItem, "keydown", igmenu_keyboard.itemKeydown, true);
			ig_shared.addEventListener(eItem, "focus", igmenu_keyboard.onitemfocus, true);
		}
		else
		{
			ig_shared.addEventListener(eItem, "mouseover", igmenu_mouseover, true);
			ig_shared.addEventListener(eItem, "mouseout", igmenu_mouseout, true);
			ig_shared.addEventListener(eItem, "mousedown", igmenu_mousedown, true);
			ig_shared.addEventListener(eItem, "mouseup", igmenu_mouseup, true);
			/* D.M. BR21320 10/23/2006 - Added separate keyboard navigation for section 508 support
			* see igmenu_keyboardWith508Support for details. */
			if (oMenu._isSection508Compliant)
				ig_shared.addEventListener(eItem, "keydown", igmenu_keyboardWith508Support.itemKeydown, true);
			else
			{
				ig_shared.addEventListener(eItem, "keydown", igmenu_keyboard.itemKeydown, true);
				ig_shared.addEventListener(eItem, "focus", igmenu_keyboard.onitemfocus, true);
			}
		}
	}

}

function igmenu_ExecuteItem()
{
	ig_startClick = true;
	igmenu_mouseup(); //evt, oItemElement);
}

function igmenu_pageUnload()
{
	if (ig_csom.IsIE55Plus)
	{
		/*
		ig_delete(igmenu_panelArray);
		*/
		for (var id in igmenu_array)
			igmenu_array[id].base = null;
		ig_delete(igmenu_array);
		ig_delete(igmenu_itemArray);
		ig_delete(igmenu_submenuArray);
	}
}

var igmenu_keyboard = new menu_Keyboard();
function menu_Keyboard()
{
	var _this = this;
	this.onfocus = function(evnt)
	{
		if (ig_csom.IsFireFox)
			return;
		var eSubMenu = ig.getSourceElement(evnt);
		var oMenu = igmenu_getMenuByItemId(eSubMenu.id);
		var oSubMenu = igmenu_getSubMenuById(oMenu, eSubMenu.id);
		var oItem = _this.getFirstKbItem(oSubMenu);
		if (oItem)
		{
			_this.showActive(oItem);
			_this.showAndActivateSubMenu(oItem);
		}
	}

	this.onitemfocus = function(evnt)
	{
		if (evnt.altKey == false || !evnt.altKey)
			return;
		var eItem = ig_fromEvent(evnt);
		var oItem = igmenu_getItemById(eItem.id);
		var oMenu = oItem.WebMenu;
		var oSubMenu = oItem.getChildSubMenu();
		if (oItem && oItem.getLevel() == 0 && oMenu.MenuTarget == 1)
		{
			var oChildItem = oItem.getFirstChild();
			if (oChildItem)
				_this.showAndActivateSubMenu(oItem);
			else
				oItem.activate();
		}
	}

	this.itemKeydown = function(evnt)
	{
		if (evnt.keyCode == 18)
			return;
		var eItem = ig_fromEvent(evnt);
		var oItem = igmenu_getItemById(eItem.id);
		if(oItem != null && !oItem.getEnabled())
		{
		    /* AS 2009-12-17 / TFS#25653 just skip any keyboard interaction when item is disabled! */
		    return;
		}
		var oMenu = oItem.WebMenu;
		var oSubMenu = oItem.getChildSubMenu();
		var oOwnerSubMenu = oItem.getOwnerSubMenu();

		if ((evnt.keyCode >= 48 && evnt.keyCode <= 57) || // 0 - 9
				(evnt.keyCode >= 65 && evnt.keyCode <= 122)) // A - Z a - z
			return (_this.processAccessKey(oMenu, oItem, evnt.keyCode));

		var iLevel = oItem.getLevel();
		var oNextItem;
		if (oMenu.isDrillDown())
		{
			switch (evnt.keyCode)
			{
				case 32: // space
					var oChildItem = oItem.getFirstChild();
					if (oChildItem)
						_this.showAndActivateSubMenu(oItem);
					else
						oItem.activate();
					break;
				case 9: // tab
					return;
					break;
				case 37: // left arrow
				case 27: // escape
					oNextItem = oItem.getParent();
					if (oNextItem)
					{
						oItem.unhover();
						if (oOwnerSubMenu)
						{
							oldOnEnd = oMenu.viewport.animate.onEnd;
							oMenu.viewport.animate.onEnd = function()
							{
								oNextItem.focus();
								oMenu.viewport.animate.onEnd = oldOnEnd;
							}
							oOwnerSubMenu.drillDownUnDisplay();
						}
					}
					else
					{
						oItem.unhover();
					}
					break;
				case 38: // up arrow
					oNextItem = _this.getNextKbItem(oItem, -1);
					_this.showActive(oNextItem);
					break;
				case 39: // right arrow
					var oChildItem = oItem.getFirstChild();
					if (oChildItem)
						_this.showAndActivateSubMenu(oItem);
					break;
				case 40: // down arrow			
					oNextItem = _this.getNextKbItem(oItem, 1);
					_this.showActive(oNextItem);
					break;
			}
		}
		else
		{
			var isHorizontal = oMenu.isHorizontal();
			var bTopHorizontal = isHorizontal && iLevel == 0;

			switch (evnt.keyCode)
			{
				case 32: // space
					var oChildItem = oItem.getFirstChild();
					if (oChildItem)
						_this.showAndActivateSubMenu(oItem);
					else
						oItem.activate();
					break;
				case 9: // tab
					oMenu.hideSubMenus();
					break;
				case 37: // left arrow
					if (isHorizontal && (iLevel == 0 || iLevel == 1))
					{
						_this.showNextTopKbItem(oItem, -1);
						return;
					}
					// fall thru
				case 27: // escape
					oNextItem = oItem.getParent();
					if (oNextItem)
					{
						if (oOwnerSubMenu)
						{
							oOwnerSubMenu.dismiss();
						}
						_this.showActive(oNextItem);
					}
					else
					{
						oItem.unhover();
					}
					break;
				case 38: // up arrow
					if (bTopHorizontal)
					{
						oSubMenu = oItem.getChildSubMenu();
						if (oSubMenu)
							oSubMenu.show(oItem);
					}
					else
					{
						oNextItem = _this.getNextKbItem(oItem, -1);
						_this.showActive(oNextItem);
					}
					break;
				case 39: // right arrow
					if (bTopHorizontal)
					{
						_this.showNextTopKbItem(oItem, 1)
					}
					else
					{
						var oChildItem = oItem.getFirstChild();
						if (oChildItem)
							_this.showAndActivateSubMenu(oItem);
						else
							if (isHorizontal)
						{
							_this.showNextTopKbItem(oItem, 1);
						}
					}
					break;
				case 40: // down arrow			
					if (bTopHorizontal)
					{
						if (!oItem.getFirstChild())
							_this.showActive(oItem);
						else
						{
							_this.showAndActivateSubMenu(oItem);
						}
					}
					else
					{
						oNextItem = _this.getNextKbItem(oItem, 1);
						_this.showActive(oNextItem);
					}
					break;
			}
		}
		ig_cancelEvent();
	}

	this.showActive = function(oItem)
	{
		if (oItem)
		{
			var oOwner = oItem.getOwnerSubMenu();
			oOwner.dismissDescendantSubMenus();
			oItem.hover();
		}
	}

	this.showNextTopKbItem = function(oItem, iDirection)
	{
		while (oItem.getLevel() > 0)
			oItem = oItem.getParent();
		var oNextItem = _this.getNextKbItem(oItem, iDirection);
		if (oNextItem)
		{
			//var useAnimation = constUseAnimation;
			//constUseAnimation = false;
			var oChildItem = oNextItem.getFirstChild();
			if (oChildItem)
				_this.showAndActivateSubMenu(oNextItem);
			else
				_this.showActive(oNextItem);
			//constUseAnimation = useAnimation;
		}
	}

	this.showAndActivateSubMenu = function(oItem)
	{
		var oSubMenu = oItem.getChildSubMenu();
		var oOwner = oItem.getOwnerSubMenu();
		if (!oSubMenu)
			return;

		if (oItem.WebMenu.isDrillDown())
		{
			oldOnEnd = oItem.WebMenu.viewport.animate.onEnd;
			var oChild = _this.getFirstKbChild(oItem);
			if (oChild)
			{
				oItem.WebMenu.viewport.animate.onEnd = function()
				{
					oChild.hover();
					oItem.WebMenu.viewport.animate.onEnd = oldOnEnd;
				}
			}
			oSubMenu.drillDownDisplay(oOwner, oItem);
		}
		else
		{
			oOwner.dismissDescendantSubMenus(oSubMenu);
			oItem.WebMenu.TopHoverStarted = true;
			oSubMenu.show(oItem);
			oItem.WebMenu.TopHoverStarted = false;
			var oChild = _this.getFirstKbChild(oItem);
			if (oChild)
			{
				oChild.hover();
			}

		}
	}

	this.getFirstKbChild = function(oItem)
	{
		var firstChild = oItem.getFirstChild();
		if (!firstChild.getEnabled() || firstChild.isSeparator())
			firstChild = _this.getNextKbItem(firstChild);
		return firstChild;
	}

	this.getFirstKbItem = function(oSubMenu)
	{
		var items = oSubMenu.getItems();
		for (var i = 0; i < items.length; i++)
		{
			var item = items[i];
			if (item.getEnabled() || !item.isSeparator())
				return item;
		}

		return null;
	}

	this.getNextKbItem = function(oItem, bForward)
	{
		var oNextItem = oItem;
		if (!bForward)
			bForward = 1;
		do
		{
			if (bForward == 1)
			{
				oNextItem = oNextItem.getNextSibling();
				if (!oNextItem)
				{
					if (oItem.getLevel() == 0)
						oNextItem = oItem.WebMenu.getItems();
					else
						oNextItem = oItem.getParent().getItems();
					if (oNextItem)
						oNextItem = oNextItem[0];
				}
			}
			else
			{
				oNextItem = oNextItem.getPrevSibling();
				if (!oNextItem)
				{
					if (oItem.getLevel() == 0)
						oNextItem = oItem.WebMenu.getItems();
					else
						oNextItem = oItem.getParent().getItems();
					if (oNextItem)
						oNextItem = oNextItem[oNextItem.length - 1];
				}
			}
			if (oNextItem == oItem)
				return null;
		}
		while (oNextItem && (!oNextItem.getEnabled() || oNextItem.isSeparator()));
		return oNextItem;
	}

	this.accessKeyMatch = function(oItem, keyCode)
	{
		var accessKey = oItem.getAccessKey();
		if (ig.notEmpty(accessKey))
		{
			if (accessKey.toLocaleLowerCase().charCodeAt(0) == keyCode ||
				accessKey.toLocaleUpperCase().charCodeAt(0) == keyCode)
				if (oItem.getEnabled() && !oItem.isSeparator())
				return true;
		}
		return false;
	}

	this.processAccessKey = function(oMenu, oItem, keyCode)
	{
		var accessItem = this.processChildAccess(oMenu, oItem, keyCode);
		if (accessItem == null)
		{
			accessItem = this.processParentAccess(oMenu, oItem, keyCode);
		}
		if (accessItem != null)
		{
			var oOwnerSubMenu = accessItem.getOwnerSubMenu();
			var oChildSubMenu = accessItem.getChildSubMenu();
			if (oChildSubMenu)
			{
				_this.showAndActivateSubMenu(accessItem);
			}
			else
			{
				accessItem.activate();
				oOwnerSubMenu.dismissDescendantSubMenus();
			}
		}

	}

	this.processChildAccess = function(oMenu, oItem, keyCode)
	{
		var oItems = oItem.getItems();
		var oChild = null;
		var accessKey;
		for (var i = 0; i < oItems.length; i++)
		{
			oChild = oItems[i];
			if (this.accessKeyMatch(oChild, keyCode))
				return oChild;
		}
		return null;
	}

	this.processParentAccess = function(oMenu, oParentItem, keyCode)
	{
		if (oParentItem == null)
			return null;
		var oNextItem = oParentItem.getNextSibling();
		while (true)
		{
			if (oNextItem == null)
			{
				var oItems;
				if (oParentItem.getLevel() == 0)
					oItems = oMenu.getItems();
				else
					oItems = oParentItem.getParent().getItems();
				oNextItem = oItems[0];
			}
			if (_this.accessKeyMatch(oNextItem, keyCode))
				return oNextItem;
			if (oParentItem == oNextItem)
				return this.processParentAccess(oMenu, oParentItem.getParent(), keyCode);
			oNextItem = oNextItem.getNextSibling();
		}
	}
}
/* D.M. BR21320 10/23/2006 - Added separate keyboard navigation for section 508 support
* for the time being this should only be used when the user has enabled section 508 support.
* All of the major changes were made in onfocus, onmenufocus, onmenublur, menukeydown, and itemkeydown.
* Previously we were doing too much to handle the tab key during navigation, unfortunately
* the way we were doing that caused the focus to get stuck on the menu, so once a user tabbed into
* it they would be unable to navigate to any other controls using the tab key.  In this implementation
* we take a hands off approach with the tab key and just allow it to navigate to the next element in the
* tab order.  Instead of tab the user is expected to use the arrow keys for the majority of their navigation.
* Also note, drill down behavior has not been altered.
*/
var igmenu_keyboardWith508Support = new menu_KeyboardWith508Support();
function menu_KeyboardWith508Support()
{
	var _this = this;
	this.onfocus = function(evnt)
	{
		if (ig_csom.IsFireFox)
			return;
		var eSubMenu = ig.getSourceElement(evnt);
		var name = igmenu_getMenuNameByItemId(eSubMenu.id);

		var oMenu = igmenu_getMenuById(name);
		var oSubMenu = igmenu_getSubMenuById(oMenu, eSubMenu.id);
		var oItem = oMenu.__activeItem;
		if (!oItem)
			oItem = _this.getFirstKbItem(oSubMenu);
	}

	this.onmenufocus = function(evnt)
	{
		if (evnt.altKey == false)
			return;
		var eMenu = ig_fromEvent(evnt);
		var name = igmenu_getMenuNameByItemId(eMenu.id);

		var oMenu = igmenu_getMenuById(name);
		var oItem = _this.getFirstKbItem(oSubMenu);

		// RCS 02/20/2008 BR29540 - oItem is null in FireFox with SiteMapDataSource			
		var oSubMenu;
		if (oItem)
			oSubMenu = oItem.getChildSubMenu();

		if (oItem && oItem.getLevel() == 0 && oMenu.MenuTarget == 1)
		{
			var oChildItem = oItem.getFirstChild();
			if (oChildItem)
				_this.showAndActivateSubMenu(oItem);
			else
				oItem.activate();
		}
	}

	this.onmenublur = function(evnt)
	{
		var eMenu = ig_fromEvent(evnt);
		var name = igmenu_getMenuNameByItemId(eMenu.id);

		var oMenu = igmenu_getMenuById(name);
	}

	this.menuKeydown = function(evnt)
	{
		if (evnt.keyCode == 18)
			return;
		var eMenu = ig_fromEvent(evnt);
		var name = igmenu_getMenuNameByItemId(eMenu.id);

		var oMenu = igmenu_getMenuById(name);


		var oItem = oMenu.__activeItem;
		if (!oItem)
			oItem = _this.getFirstKbItem(oMenu);

		var oSubMenu = oItem.getChildSubMenu();
		var oOwnerSubMenu = oItem.getOwnerSubMenu();

		if ((evnt.keyCode >= 48 && evnt.keyCode <= 57) || // 0 - 9
				(evnt.keyCode >= 65 && evnt.keyCode <= 122)) // A - Z a - z
			return (_this.processAccessKey(oMenu, oItem, evnt.keyCode));

		var iLevel = oItem.getLevel();
		var oNextItem;
		if (oMenu.isDrillDown())
		{
			switch (evnt.keyCode)
			{
				case 32: // space
					var oChildItem = oItem.getFirstChild();
					if (oChildItem)
						_this.showAndActivateSubMenu(oItem);
					else
						oItem.activate();
					break;
				case 9: // tab
					return;
					break;
				case 37: // left arrow
				case 27: // escape
					oNextItem = oItem.getParent();
					if (oNextItem)
					{
						oItem.unhover();
						if (oOwnerSubMenu)
						{
							oldOnEnd = oMenu.viewport.animate.onEnd;
							oMenu.viewport.animate.onEnd = function()
							{
								oNextItem.focus();
								oMenu.viewport.animate.onEnd = oldOnEnd;
							}
							oOwnerSubMenu.drillDownUnDisplay();
						}
					}
					else
					{
						oItem.unhover();
					}
					break;
				case 38: // up arrow
					oNextItem = _this.getNextKbItem(oItem, -1);
					_this.showActive(oNextItem);
					break;
				case 39: // right arrow
					var oChildItem = oItem.getFirstChild();
					if (oChildItem)
						_this.showAndActivateSubMenu(oItem);
					break;
				case 40: // down arrow			
					oNextItem = _this.getNextKbItem(oItem, 1);
					_this.showActive(oNextItem);
					break;
			}
		}
		else
		{
			var isHorizontal = oMenu.isHorizontal();
			var bTopHorizontal = isHorizontal && iLevel == 0;

			switch (evnt.keyCode)
			{
				case 32: // space
					var oChildItem = oItem.getFirstChild();
					if (oChildItem)
						_this.showAndActivateSubMenu(oItem);
					else
						oItem.activate();
					break;
				case 9: // tab

					oMenu.hideSubMenus();
					if (oMenu.__activeItem)
						oMenu.__activeItem.unhover();

					return;
					break;
				case 37: // left arrow
					if (bTopHorizontal)
					{
						oNextItem = _this.getNextKbItem(oItem, -1);
						oNextItem.hover();
					}
					else if (oOwnerSubMenu)
					{
						if (oOwnerSubMenu._ownerItem.getLevel() == 0)
							_this.showNextTopKbItem(oItem, -1);
						else
						{
							oOwnerSubMenu._ownerItem.hover();
							oOwnerSubMenu.dismiss();
						}
					}
					// fall thru
				case 27: // escape
					oNextItem = oItem.getParent();
					if (oNextItem)
					{
						if (oOwnerSubMenu)
						{
							oOwnerSubMenu.dismiss();
						}
						_this.showActive(oNextItem);
					}
					else
					{
						oItem.unhover();
						/*D.M. BR31862 6/17/2008 - Dismiss if it's a popup.*/
						if (oMenu.isPopup())
							oMenu.dismiss();
					}
					break;
				case 38: // up arrow
					if (bTopHorizontal)
					{
						oSubMenu = oItem.getChildSubMenu();
						if (oSubMenu)
							oSubMenu.show(oItem);
					}
					else
					{
						oNextItem = _this.getNextKbItem(oItem, -1);
						_this.showActive(oNextItem);
					}
					break;
				case 39: // right arrow
					if (isHorizontal && (iLevel == 0 || iLevel == 1) && oItem.getPrevSibling() != null)
					{
						oItem.getNextSibling().hover();
						return;
					}
					else if (oItem.getPrevSibling() == null)
					{
						oItem.hover();
						return;
					}
					break;
				case 40: // down arrow			
					if (bTopHorizontal)
					{
						if (!oItem.getFirstChild())
							_this.showActive(oItem);
						else
						{
							_this.showAndActivateSubMenu(oItem);
							var oChildSubMenu = oItem.getChildSubMenu();
							oItem.__displaySubMenu(oChildSubMenu);
							oItem.getFirstChild().hover();
						}
					}
					break;
			}
		}
		ig_cancelEvent();
	}

	this.itemKeydown = function(evnt)
	{
		if (evnt.keyCode == 18)
			return;
		var eItem = ig_fromEvent(evnt);
		var oItem = igmenu_getItemById(eItem.id);
		var oMenu = oItem.WebMenu;
		var oSubMenu = oItem.getChildSubMenu();
		var oOwnerSubMenu = oItem.getOwnerSubMenu();

		if ((evnt.keyCode >= 48 && evnt.keyCode <= 57) || // 0 - 9
				(evnt.keyCode >= 65 && evnt.keyCode <= 122)) // A - Z a - z
			return (_this.processAccessKey(oMenu, oItem, evnt.keyCode));

		var iLevel = oItem.getLevel();
		var oNextItem;
		if (oMenu.isDrillDown())
		{
			switch (evnt.keyCode)
			{
				case 32: // space
					var oChildItem = oItem.getFirstChild();
					if (oChildItem)
						_this.showAndActivateSubMenu(oItem);
					else
						oItem.activate();
					break;
				case 9: // tab
					return;
					break;
				case 37: // left arrow
				case 27: // escape
					oNextItem = oItem.getParent();
					if (oNextItem)
					{
						oItem.unhover();
						if (oOwnerSubMenu)
						{
							oldOnEnd = oMenu.viewport.animate.onEnd;
							oMenu.viewport.animate.onEnd = function()
							{
								oNextItem.focus();
								oMenu.viewport.animate.onEnd = oldOnEnd;
							}
							oOwnerSubMenu.drillDownUnDisplay();
						}
					}
					else
					{
						oItem.unhover();
					}
					break;
				case 38: // up arrow
					oNextItem = _this.getNextKbItem(oItem, -1);
					_this.showActive(oNextItem);
					break;
				case 39: // right arrow
					var oChildItem = oItem.getFirstChild();
					if (oChildItem)
						_this.showAndActivateSubMenu(oItem);
					break;
				case 40: // down arrow			
					oNextItem = _this.getNextKbItem(oItem, 1);
					_this.showActive(oNextItem);
					break;
			}
		}
		else
		{
			var isHorizontal = oMenu.isHorizontal();
			var bTopHorizontal = isHorizontal && iLevel == 0;

			switch (evnt.keyCode)
			{
				case 32: // space
					var oChildItem = oItem.getFirstChild();
					if (oChildItem)
						_this.showAndActivateSubMenu(oItem);
					else
						oItem.activate();
					break;
				case 9: // tab
					return;
					break;
				case 37: // left arrow
					if (bTopHorizontal)
					{

						oNextItem = _this.getNextKbItem(oItem, -1);
						if (oNextItem)
							oNextItem.hover();
					}
					else if (oOwnerSubMenu)
					{
						if (oOwnerSubMenu._ownerItem != null)
						{
							if (oOwnerSubMenu._ownerItem.getLevel() == 0)
							{
								/* D.M. TFS6441 11/19/2008 - Changed keyboard navigation for vertical menus.*/
								oOwnerSubMenu.dismiss();
								oNextItem = _this.getNextKbItem(oOwnerSubMenu._ownerItem, -1)
								oOwnerSubMenu._ownerItem.hover();
							}
							else
							{
								oOwnerSubMenu._ownerItem.hover();
								oOwnerSubMenu.dismiss();
							}
						}
					}
					break;
				case 27: // escape
					oNextItem = oItem.getParent();
					if (oNextItem)
					{
						if (oOwnerSubMenu)
						{
							oOwnerSubMenu.dismiss();
						}
						_this.showActive(oNextItem);
					}
					else
					{
						oItem.unhover();
						/*D.M. BR31862 6/17/2008 - Dismiss if it's a popup.*/
						if (oMenu.isPopup())
							oMenu.dismiss();
					}
					break;
				case 38: // up arrow
					if (bTopHorizontal)
					{
						oSubMenu = oItem.getChildSubMenu();
						if (oSubMenu)
							oSubMenu.show(oItem);
					}
					else
					{
						oNextItem = _this.getNextKbItem(oItem, -1);
						_this.showActive(oNextItem);
					}
					break;
				case 39: // right arrow
					if (bTopHorizontal)
					{
						oNextItem = _this.getNextKbItem(oItem, 1);
						if (oNextItem)
							oNextItem.hover();
					}
					else
					{
						var oChildItem = oItem.getFirstChild();
						if (oChildItem)
							_this.showAndActivateSubMenu(oItem);
						else
							if (isHorizontal)
						{
							_this.showNextTopKbItem(oItem, 1);
						}
					}
					break;
				case 40: // down arrow			
					if (bTopHorizontal)
					{
						if (!oItem.getFirstChild())
							oItem.hover();
						else
						{
							_this.showAndActivateSubMenu(oItem);
							var oChildSubMenu = oItem.getChildSubMenu();
							oNextItem = _this.getFirstKbItem(oChildSubMenu);
							_this.showActive(oNextItem);
							oNextItem.hover();
						}
					}
					else
					{
						oNextItem = _this.getNextKbItem(oItem, 1);
						if(oNextItem)
							oNextItem.hover();
					}
					break;
			}
		}
		ig_cancelEvent();
	}

	this.showActive = function(oItem)
	{
		if (oItem)
		{
			var oOwner = oItem.getOwnerSubMenu();
			oOwner.dismissDescendantSubMenus();
			oItem.hover();
		}
	}

	this.showNextTopKbItem = function(oItem, iDirection)
	{
		while (oItem.getLevel() > 0)
			oItem = oItem.getParent();
		var oNextItem = _this.getNextKbItem(oItem, iDirection);
		if (oNextItem)
		{
			//var useAnimation = constUseAnimation;
			//constUseAnimation = false;
			var oChildItem = oNextItem.getFirstChild();
			if (oChildItem)
				_this.showAndActivateSubMenu(oNextItem);
			else
				_this.showActive(oNextItem);
			//constUseAnimation = useAnimation;
		}
	}

	this.showAndActivateSubMenu = function(oItem)
	{
		var oSubMenu = oItem.getChildSubMenu();
		var oOwner = oItem.getOwnerSubMenu();
		if (!oSubMenu)
			return;

		if (oItem.WebMenu.isDrillDown())
		{
			oldOnEnd = oItem.WebMenu.viewport.animate.onEnd;
			var oChild = _this.getFirstKbChild(oItem);
			if (oChild)
			{
				oItem.WebMenu.viewport.animate.onEnd = function()
				{
					oChild.hover();
					oItem.WebMenu.viewport.animate.onEnd = oldOnEnd;
				}
			}
			oSubMenu.drillDownDisplay(oOwner, oItem);
		}
		else
		{
			oOwner.dismissDescendantSubMenus(oSubMenu);
			oItem.WebMenu.TopHoverStarted = true;
			oSubMenu.show(oItem);
			oItem.WebMenu.TopHoverStarted = false;
			var oChild = _this.getFirstKbChild(oItem);
			if (oChild)
			{
				oChild.hover();
			}

		}
	}

	this.getFirstKbChild = function(oItem)
	{
		var firstChild = oItem.getFirstChild();
		if (!firstChild.getEnabled() || firstChild.isSeparator())
			firstChild = _this.getNextKbItem(firstChild);
		return firstChild;
	}

	this.getFirstKbItem = function(oSubMenu)
	{
		if (oSubMenu)
		{
			var items = oSubMenu.getItems();
			for (var i = 0; i < items.length; i++)
			{
				var item = items[i];
				if (item.getEnabled() || !item.isSeparator())
					return item;
			}
		}
		return null;
	}

	this.getNextKbItem = function(oItem, bForward)
	{
		var oNextItem = oItem;
		if (!bForward)
			bForward = 1;
		do
		{
			if (bForward == 1)
			{
				oNextItem = oNextItem.getNextSibling();
				if (!oNextItem)
				{
					if (oItem.getLevel() == 0)
						oNextItem = oItem.WebMenu.getItems();
					else
						oNextItem = oItem.getParent().getItems();
					if (oNextItem)
						oNextItem = oNextItem[0];
				}
			}
			else
			{
				oNextItem = oNextItem.getPrevSibling();
				if (!oNextItem)
				{
					if (oItem.getLevel() == 0)
						oNextItem = oItem.WebMenu.getItems();
					else
						oNextItem = oItem.getParent().getItems();
					if (oNextItem)
						oNextItem = oNextItem[oNextItem.length - 1];
				}
			}
			if (oNextItem == oItem)
				return null;
		}
		while (oNextItem && (!oNextItem.getEnabled() || oNextItem.isSeparator()));
		return oNextItem;
	}

	this.accessKeyMatch = function(oItem, keyCode)
	{
		var accessKey = oItem.getAccessKey();
		if (ig.notEmpty(accessKey))
		{
			if (accessKey.toLocaleLowerCase().charCodeAt(0) == keyCode ||
				accessKey.toLocaleUpperCase().charCodeAt(0) == keyCode)
				if (oItem.getEnabled() && !oItem.isSeparator())
				return true;
		}
		return false;
	}

	this.processAccessKey = function(oMenu, oItem, keyCode)
	{
		var accessItem = this.processChildAccess(oMenu, oItem, keyCode);
		if (accessItem == null)
		{
			accessItem = this.processParentAccess(oMenu, oItem, keyCode);
		}
		if (accessItem != null)
		{
			var oOwnerSubMenu = accessItem.getOwnerSubMenu();
			var oChildSubMenu = accessItem.getChildSubMenu();
			if (oChildSubMenu)
			{
				_this.showAndActivateSubMenu(accessItem);
			}
			else
			{
				accessItem.activate();
				oOwnerSubMenu.dismissDescendantSubMenus();
			}
		}

	}

	this.processChildAccess = function(oMenu, oItem, keyCode)
	{
		var oItems = oItem.getItems();
		var oChild = null;
		var accessKey;
		for (var i = 0; i < oItems.length; i++)
		{
			oChild = oItems[i];
			if (this.accessKeyMatch(oChild, keyCode))
				return oChild;
		}
		return null;
	}

	this.processParentAccess = function(oMenu, oParentItem, keyCode)
	{
		if (oParentItem == null)
			return null;
		var oNextItem = oParentItem.getNextSibling();
		while (true)
		{
			if (oNextItem == null)
			{
				var oItems;
				if (oParentItem.getLevel() == 0)
					oItems = oMenu.getItems();
				else
					oItems = oParentItem.getParent().getItems();
				oNextItem = oItems[0];
			}
			if (_this.accessKeyMatch(oNextItem, keyCode))
				return oNextItem;
			if (oParentItem == oNextItem)
				return this.processParentAccess(oMenu, oParentItem.getParent(), keyCode);
			oNextItem = oNextItem.getNextSibling();
		}
	}
}

// private - constructor for the menu scroll object
function igmenu_scroller(subMenuElement)
{
	this.subMenu = subMenuElement;
	this.fullHeight = this.subMenu.offsetHeight;
	this.active = false;
	this.oMenu = igmenu_getMenuByItemId(this.subMenu.id);

	// private - implements the showing and hiding of submenus
	this.addScroll = function()
	{
		this.scrollDiv = this.subMenu.firstChild
		this.table = this.scrollDiv.firstChild;
        /* AS 2009-05-12 TFS#17393 dirty hack to allow scrollers be on top of menu items 
		*  this is kind-of dynamic rollback of fix for TFS#6441
		*  because that fix made a regression TFS#17292
		*/
		this.table.style.position="static";		
		this.topDiv = window.document.createElement("TABLE");
		this.topDiv.topDiv = true;
		this.bottomDiv = window.document.createElement("TABLE");
		this.bottomDiv.bottomDiv = true;

		var tbody = window.document.createElement("TBODY");
		var tr = window.document.createElement("TR");
		var td = window.document.createElement("TD");
		this.topDiv.appendChild(tbody);
		tbody.appendChild(tr);
		tr.appendChild(td);
		td.align = 'center';
		this.topDiv.style.width = this.subMenu.offsetWidth + "px";

		tbody = window.document.createElement("TBODY");
		tr = window.document.createElement("TR");
		td = window.document.createElement("TD");
		this.bottomDiv.appendChild(tbody);
		tbody.appendChild(tr);
		tr.appendChild(td);
		td.align = 'center';
		this.bottomDiv.style.width = this.subMenu.offsetWidth + "px";

		// add image elements to top and bottom divs
		var img = window.document.createElement("IMG");
		img.src = this.oMenu.ScrollImageTopDisabled;
		this.topDiv.cells[0].appendChild(img);
		img = window.document.createElement("IMG");
		img.src = this.oMenu.ScrollImageBottom;
		this.bottomDiv.cells[0].appendChild(img);

		// top and bottom divs to the document object
		this.subMenu.insertBefore(this.topDiv, this.subMenu.firstChild);
		this.subMenu.appendChild(this.bottomDiv);

		if (!ig_csom.isEmpty(this.oMenu.DefaultItemClass))
		{
			this.topDiv.className = this.oMenu.DefaultItemClass;
			this.bottomDiv.className = this.oMenu.DefaultItemClass;
		}
		// Add mouse event listeners to top and bottom divs
		if (this.topDiv._old)
			return;
		this.topDiv._old = true;
		ig_csom.addEventListener(this.topDiv, "mouseover", igmenu_onScrollMouseOver, true);
		ig_csom.addEventListener(this.bottomDiv, "mouseover", igmenu_onScrollMouseOver, true);
		ig_csom.addEventListener(this.topDiv, "mouseout", igmenu_onScrollMouseOut, true);
		ig_csom.addEventListener(this.bottomDiv, "mouseout", igmenu_onScrollMouseOut, true);
	}
	this.setScrollHeight = function(scrollHeight)
	{
		if (scrollHeight >= 0)
		{
			var width = this.scrollDiv.offsetWidth;
			this.scrollDiv.style.height = scrollHeight;
			this.scrollDiv.style.width = width + "px";
		}
	}
	this.getScrollHeight = function()
	{
		return this.scrollDiv.style.height;
	}
	this.show = function()
	{
		if (this.topDiv.cells[0].innerHTML.indexOf(this.oMenu.ScrollImageTopDisabled) == -1)
			this.topDiv.cells[0].innerHTML = "<img src='" + this.oMenu.ScrollImageTopDisabled + "'>"
		if (this.bottomDiv.cells[0].innerHTML.indexOf(this.oMenu.ScrollImageBottom) == -1)
			this.bottomDiv.cells[0].innerHTML = "<img src='" + this.oMenu.ScrollImageBottom + "'>"
		this.scrollDiv.scrollTop = 0;
		this.scrollDiv.style.overflow = "hidden";
		this.topDiv.style.display = "";
		this.topDiv.style.visibility = "visible";
		this.bottomDiv.style.display = "";
		this.bottomDiv.style.visibility = "visible";
		this.active = true;
	}
	this.hide = function()
	{
	   /* AS 2009-05-12 TFS#17393 dirty hack to allow scrollers be on top of menu items 
		*  give back relative positioning upon hiding.
		*/
		this.table.style.position="relative";
		this.topDiv.style.display = "none";
		this.topDiv.style.visibility = "hidden";
		this.bottomDiv.style.display = "none";
		this.bottomDiv.style.visibility = "hidden";
		this.subMenu.style.height = this.fullHeight;
		this.scrollDiv.style.overflow = "";
		this.active = false;
	}
	this.addScroll();
}

// private - handles mouse over for scrollable submenus
var igmenu_scrollTimerId;
var igmenu_oScrollMenu;
function igmenu_onScrollMouseOver(evnt)
{
	var e = ig_fromEvent(evnt);

	ig_inMenu = true;
	clearTimeout(igmenu_clearMenuTimerId);
	clearCurrentMenu = false;
	var oMenu = igmenu_getMenuByItemId(e.parentNode.id);
	igmenu_oScrollMenu = igmenu_getSubMenuById(oMenu, e.parentNode.id);


	var hoverClass = oMenu.HoverClass;
	if (oMenu.MergeStyles)
		e.className += " " + hoverClass;
	else
		e.className = hoverClass;

	if (e.topDiv)
	{
		igmenu_oScrollMenu.scrollInc = -3;
	}
	else
		if (e.bottomDiv)
	{
		igmenu_oScrollMenu.scrollInc = 3;
	}
	clearInterval(igmenu_scrollTimerId);
	igmenu_scrollTimerId = setInterval(igmenu_onMenuScroll, 4);
}

// private - handles mouse out for scrollable submenus
function igmenu_onScrollMouseOut(evnt)
{
	var e = ig_fromEvent(evnt);

	var oMenu = igmenu_getMenuByItemId(e.parentNode.id);
	var itemClass = oMenu.DefaultItemClass;
	e.className = itemClass;

	clearInterval(igmenu_scrollTimerId);
	igmenu_oScrollMenu = null;
	/* OK 3/10/08 BR27155 - set ig_inMenu to false, so the mouse down even will be handeled by
	the igmenu_pageMouseDown and the popup menu will be hidden on mouse out */
	ig_inMenu = false;
	clearCurrentMenu = true;
	clearTimeout(igmenu_clearMenuTimerId);
	igmenu_clearMenuTimerId = setTimeout('clearTimerExpired()', oMenu.ExpandEffects.RemovalDelay);
}

// private - handles scrolling for scrollable submenus
function igmenu_onMenuScroll()
{
	if (igmenu_oScrollMenu != null)
	{
		var scrollDiv = igmenu_oScrollMenu.scroller.scrollDiv;

		// save the current scrollTop position
		var oldValue = scrollDiv.scrollTop;

		// increment the scrollTop property of the scrollDiv
		scrollDiv.scrollTop += igmenu_oScrollMenu.scrollInc;

		// get references to the top and bottom divs and the menu object
		var topDiv = igmenu_oScrollMenu.scroller.topDiv;
		var bottomDiv = igmenu_oScrollMenu.scroller.bottomDiv;
		var oMenu = igmenu_oScrollMenu.scroller.oMenu;

		// If at the top, display disabled up arrow
		if (scrollDiv.scrollTop == 0)
		{
			if (topDiv.innerHTML.indexOf(oMenu.ScrollImageTopDisabled) == -1)
			{
				topDiv.cells[0].innerHTML = "<img src='" + oMenu.ScrollImageTopDisabled + "'>"
				clearInterval(igmenu_scrollTimerId);
			}
		}
		else
		{
			if (topDiv.cells[0].innerHTML.indexOf(oMenu.ScrollImageTop) == -1)
				topDiv.cells[0].innerHTML = "<img src='" + oMenu.ScrollImageTop + "'>"
		}

		// If at the bottom, display disabled down arrow
		if (oldValue == scrollDiv.scrollTop && oldValue > 0)
		{
			if (bottomDiv.cells[0].innerHTML.indexOf(oMenu.ScrollImageBottomDisabled) == -1)
			{
				bottomDiv.cells[0].innerHTML = "<img src='" + oMenu.ScrollImageBottomDisabled + "'>"
				clearInterval(igmenu_scrollTimerId);
			}
		}
		else
		{
			if (bottomDiv.cells[0].innerHTML.indexOf(oMenu.ScrollImageBottom) == -1)
				bottomDiv.cells[0].innerHTML = "<img src='" + oMenu.ScrollImageBottom + "'>"
		}

	}
}


if (typeof (ig_csom) != "undefined" && ig_csom.IsIE)
	ig_csom.addEventListener(window, "unload", igmenu_pageUnload, true);

// public - Obtains a menu Item object using its id
function igmenu_getItemById(itemId)
{
	var oItem = igmenu_itemArray[itemId];
	if (oItem)
		return oItem;
	var item = igmenu_getElementById(itemId);
	if (!item)
		return null;
	oItem = new ig_CreateMenuItem(item);
	igmenu_itemArray[itemId] = oItem;
	return oItem;
}

// public - Obtains a menu object using its id
function igmenu_getMenuById(menuId)
{
	return igmenu_array[menuId];
}

// public - returns the menu object for the Item Id
function igmenu_getMenuByItemId(itemId)
{
	var mn = igmenu_getMenuNameByItemId(itemId);
	return igmenu_array[mn];
}

// public - returns the submenu object for the SubMenu Id
function igmenu_getSubMenuById(oMenu, submenuId)
{
	var oSub = igmenu_submenuArray[submenuId];
	if (oSub)
	{
		/* SJZ 2/28/08 BR27881 - Due to a possible synchronization issue, the oSub object could be partially disposed, so lets verify its valid */
		if (oSub.WebMenu)
			return oSub;
	}
	var eSub = igmenu_getElementById(submenuId);
	if (!eSub)
		return null;
	oSub = ig_CreateSubMenu(oMenu, eSub);
	igmenu_submenuArray[submenuId] = oSub;
	return oSub;
}

// public - returns the Menu Name (mn) from an itemId
function igmenu_getMenuNameByItemId(itemId)
{
	var menuName = itemId;
	var strArray = menuName.split("_");
	menuName = strArray[0];
	return menuName;
}

// public - Retrieves an element by its tag name in a browser independant way
function igmenu_getElementById(id)
{
	return ig_csom.getElementById(id);
}

// private - 1.0 compatibility function for hiding select boxes
var igmenu_displayMenu = null;
function igmenu_callDisplayMenu(bShow, id)
{
	if (igmenu_displayMenu != null)
		igmenu_displayMenu(bShow, id);
}

// private - Performed on page initialization
function igmenu_initialize()
{
	ig_csom.addEventListener(document, "mousedown", igmenu_pageMouseDown, true);
}

function ig_CreateSubMenu(oMenu, eSub)
{
	/* D.M. BR23107 6/6/07 - We have to do this because Safari lacks support for the
	isPrototypeOf method.  This way if the method fails we fall through and use
	flags instead.*/
	var createSubmenu = false;

	try
	{
		if (!ig_WebUIElement.prototype.isPrototypeOf(ig_SubMenu.prototype))
			createSubmenu = true;
	}
	catch (e)
	{
		if (!ig_isSubmenuCreated)
			createSubmenu = true;
	}

	if (createSubmenu)
	{
		ig_SubMenu.prototype = new ig_WebUIElement();

		ig_SubMenu.prototype.getOwnerItem = function()
		{
			return (this._ownerItem);
		}

		ig_SubMenu.prototype.setOwnerItem = function(oItem)
		{
			this._ownerItem = oItem;
		}

		ig_SubMenu.prototype.getHoveredItem = function()
		{
			return (this._hoveredItem);
		}
		ig_SubMenu.prototype.setHoveredItem = function(oItem)
		{
			this._hoveredItem = oItem;
		}

		ig_SubMenu.prototype.getSelectedItem = function()
		{
			return (this._selectedItem);
		}
		ig_SubMenu.prototype.setSelectedItem = function(oItem)
		{
			this._selectedItem = oItem;
		}

		ig_SubMenu.prototype.getParentSubMenu = function()
		{
			if (this._ownerItem)
				return this._ownerItem.getOwnerSubMenu();
			return null;
		}

		ig_SubMenu.prototype.getItems = function()
		{
			if (!this.getParentSubMenu())
				return this.WebMenu.getItems();
			var itemAr = new Array();
			var id = this.element.id;
			id = id.substring(0, id.length - 1);
			id += "_";
			var index = 1;
			while (true)
			{
				var e = document.getElementById(id + index.toString());
				if (e)
					itemAr[index - 1] = igmenu_getItemById(id + index.toString());
				else
					break;
				index++;
			}
			return itemAr;
		}

		ig_SubMenu.prototype.getCurrentDisplayedSubMenu = function()
		{
			return this._currentDisplayedSubMenu
		}

		ig_SubMenu.prototype.show = function(oParentItem)
		{
			oMenu = this.WebMenu;
			if (this._visible || !oMenu || !oMenu.Element || !oParentItem.element)
				return;
			this._ownerItem = oParentItem;

			if (oMenu.isHorizontal() && oParentItem.isTopLevelItem())
			{
				oMenu.initSubMenuRoot(this);
				this._visible = true;
				this.___display(oParentItem, false);
				oParentItem.hover();
			}
			else
				if (oParentItem.getLevel() == 0)
			{
				this.oParentSubMenu = igmenu_getSubMenu(oParentItem.element);
				oMenu.initSubMenuRoot(this);
				oParentItem.hover();
				this._visible = true;
				this.___display(oParentItem, true);
			}
			else
			{
				this.oParentSubMenu = igmenu_getSubMenu(oParentItem.element);
				oParentItem.getOwnerSubMenu().dismissDescendantSubMenus();
				this._visible = true;
				this.___display(oParentItem, true);
			}
			oParentItem.getOwnerSubMenu()._currentDisplayedSubMenu = this;
			oParentItem.setSelected(true);
		} // show

		ig_SubMenu.prototype.cancelAnimation = function()
		{
			if (this.animate)
				this.animate.cancelAnimation();
			this.eContainer.style.display = "none";
			if (this._currentDisplayedSubMenu != null)
				this._currentDisplayedSubMenu.cancelAnimation();
		}

		ig_SubMenu.prototype.dismiss = function()
		{
			if (!this._visible)
				return;
			this._visible = false;
			// 1.0 unhide select elements
			igmenu_callDisplayMenu(false, this.id);
			if (this._currentDisplayedSubMenu)
			{
				this._currentDisplayedSubMenu.dismiss();
			}
			this._currentDisplayedSubMenu = null;

			if (this._selectedItem)
				this._selectedItem.unhover(false);
			this._selectedItem = null;

			if (this._hoveredItem)
				this._hoveredItem.unhover(false);
			this._hoveredItem = null;

			if (this.WebMenu.fireEvent(this.WebMenu.Events.SubMenuDisplay, "(\"" + this.WebMenu.MenuName + "\",\"" + this.id + "\", false)"))
				return;


			if (this.WebMenu.ExpandEffects.Type != 'Slide' || this._popup == true)
			{

				/* A.T. 12/08/2008 
				*   WebMenu Issue   BR32406: WebMenu crashes in JavaScript show() function when used as contextmenu with WebTree in AJAX UpdatePanel
				*/
				if (this.element.parentNode)
				{
					this.element.parentNode.style.display = "none";
					this.element.parentNode.style.visibility = "hidden";
				}
			}
			else
			{
				this.animate = new ig_SlideRevealAnimation();
				this.animate.setElement(this.element);
				this.animate.setContainer(this.element.parentNode);
				this.animate.setRate(AnimationRateEnum.Decelerate);
				this.animate.startPos = 0;
				/*D.M. BR21118 storing the original position prior to animation
				so that it can be restored later */
				this.animate.Top = this.element.offsetTop;
				if (this._vertical)
				{
					this.animate.setDirection(AnimationDirectionEnum.Left);
					this.animate.finishPos = -this.element.scrollWidth;
				}
				else
				{
					this.animate.setDirection(AnimationDirectionEnum.Up);
					this.animate.finishPos = -this.element.scrollHeight;
				}
				this.animate.onEnd = function()
				{
					this.getElement().style.top = this.Top + "px";
					this.getContainer().style.display = "none";
				}
				this.animate.play();
			}
			if ((ig_csom.IsIE && !ig_csom.IsMac) && this.transPanel != null)
			{
				this.transPanel.hide();
			}

		} // dismiss

		ig_SubMenu.prototype.dismissDescendantSubMenus = function(oPreserve)
		{
			if (oPreserve && this._currentDisplayedSubMenu == oPreserve)
				return;
			if (this._currentDisplayedSubMenu != null)
			{
				this._currentDisplayedSubMenu.dismiss();
			}
		}

		ig_SubMenu.prototype.getHeaderText = function()
		{
			if (this.eHeader)
				return this.eHeader.rows[0].cells[0].innerHTML;
			return null;
		}

		ig_SubMenu.prototype.setHeaderText = function(text)
		{
			if (this.eHeader)
				this.eHeader.rows[0].cells[0].innerHTML = text;
		}

		ig_SubMenu.prototype.addSlideHeader = function()
		{
			var eSubMenu = this.element;
			this.eHeader = window.document.createElement("TABLE");
			var tbody = window.document.createElement("TBODY");
			var tr = window.document.createElement("TR");
			var td = window.document.createElement("TD");
			this.eHeader.appendChild(tbody);
			tbody.appendChild(tr);
			tr.appendChild(td);
			td.align = 'center';
			if (!this.eHeader._old)
				ig_shared.addEventListener(this.eHeader, "mouseup", igmenu_podheadermouseup, true);
			this.eHeader._old = true;

			td.style.width = "100%";
			if (this.WebMenu.HeaderClass != null && this.WebMenu.HeaderClass.length > 0)
				this.eHeader.className = this.WebMenu.DefaultItemClass + " " + this.WebMenu.HeaderClass;
			else
			{
				this.eHeader.style.fontWeight = 800;
				this.eHeader.style.backgroundColor = "E0E0E0";
				this.eHeader.style.color = "000000";
				this.eHeader.style.borderStyle = "outset";
				this.eHeader.style.borderWidth = 1;
			}

			this.eHeader.style.width = "100%";
			if (this.eHeader.style.height == "")
				this.eHeader.style.height = "22px";
			eSubMenu.insertBefore(this.eHeader, eSubMenu.firstChild);
		}
	}

	ig_SubMenu.prototype.ensureScroller = function(scrollElement, fixedHeight)
	{
		if (ig_csom.IsIE && !ig_csom.IsMac)
		{
			var scrollHeight;
			if (!this.scroller)
				scrollHeight = scrollElement.scrollHeight;
			else
				scrollHeight = this.scroller.table.scrollHeight;
			if (scrollHeight > fixedHeight)
			{ // - 4) {
				if (!this.scroller)
				{
					this.scroller = new igmenu_scroller(this.element);
				}
				this.scroller.show();

				var divsHeight = this.scroller.topDiv.offsetHeight + this.scroller.bottomDiv.offsetHeight + 8;
				this.scroller.setScrollHeight(fixedHeight - divsHeight);
				//menuHeight = eContainer.offsetHeight;
			}
			else
			{
				if (this.scroller)
				{
					this.scroller.hide();
				}
			}
		}
	}

	ig_SubMenu.prototype.drillDownUnDisplay = function()
	{
		var oParentSubMenu = this._ownerItem.getOwnerSubMenu();

		var scrollElement;
		if (this.WebMenu.hasFrame && oParentSubMenu.element.id.indexOf("_MainM") != -1)
			scrollElement = oParentSubMenu.element.parentNode;
		else
			scrollElement = oParentSubMenu.element;

		this.WebMenu.viewport.scroll(this.element, scrollElement, AnimationDirectionEnum.Left, AnimationRateEnum.Linear);
	}

	ig_SubMenu.prototype.endScroll = function()
	{

	}

	// private - implements the showing and hiding of submenus
	ig_SubMenu.prototype.drillDownDisplay = function(oParentSubMenu, oParentItem)
	{
		this.WebMenu.initEventHandlers(this, oParentItem);
		var items = this.getItems();

		var clientWidth = this.WebMenu.viewport.div.clientWidth;
		var oItem;
		if (items.length > 0)
		{
			var oItem = items[0];
			//if(oItem.element.style.width == "")
			/*D.M. Set the width on the parent (cell) rather than the item(table)
			otherwise the items get rendered incorrectly when using an XHTML doctype*/
			oItem.element.parentNode.style.width = clientWidth + "px";
		}

		this.element.style.display = "";

		var scrollElement;
		if (this.WebMenu.hasFrame && oParentSubMenu.element.id.indexOf("_MainM") != -1)
			scrollElement = oParentSubMenu.element.parentNode;
		else
			scrollElement = oParentSubMenu.element;
		this.WebMenu.viewport.scroll(scrollElement, this.element, AnimationDirectionEnum.Right, AnimationRateEnum.Linear);

		var diff = this.element.parentNode.offsetWidth - clientWidth;
		if (oItem && (clientWidth - diff) > 0)
			oItem.element.parentNode.style.width = (clientWidth - diff) + "px";

		/*D.M. BR20074 
		Adjusting the width of the menu to accomdate for borders.
		*/
		var islandStyle = this.element.currentStyle;
		if (islandStyle == null)
		{
			var w = document.defaultView;
			if (w == null)
				w = window;
			if (w.getComputedStyle)
				islandStyle = w.getComputedStyle(this.element, '');
		}
		borderWidth = parseInt(islandStyle.borderRightWidth) + parseInt(islandStyle.borderLeftWidth);
		/* D.M. BR24283 06/28/2007 - If the borderWidth isn't set on the islandStyle just set it to 0 */
		if (isNaN(borderWidth))
			borderWidth = 0;
		this.element.style.width = (clientWidth - borderWidth) + "px";

		this.ensureScroller(this.element, this.WebMenu.viewport.div.offsetHeight - 30);
		if (!this.hasHeader)
		{
			this.addSlideHeader();
			this.hasHeader = true;
			this.setHeaderText(oParentItem.getText());
		}

	}

	// private - implements the showing and hiding of submenus
	ig_SubMenu.prototype.___display = function(oParent, vertical)
	{
		var oMenu = this.WebMenu;

		/* A.T. 12/08/2008 
		*   WebMenu Issue   BR32406: WebMenu crashes in JavaScript show() function when used as contextmenu with WebTree in AJAX UpdatePanel
		*/
		if (oMenu == null)
			return;

		oMenu._move(); /*VS 11/20/2006 */
		var eParent = null;
		var eSubMenu = this.element;
		var eContainer = this.element.parentNode;
		var effects = oMenu.ExpandEffects;

		if (oParent)
		{
			eParent = oParent.element;
			oMenu.initEventHandlers(this, oParent);
		}

		/*D.M. BR21132, BR24939 Compute scroll offset*/
		var offsetScrollY = offsetScrollX = 0;
		var currentElement = eParent;
		while (currentElement != null && currentElement.tagName != "body")
		{
			offsetScrollY += currentElement.scrollTop;
			offsetScrollX += currentElement.scrollLeft;
			currentElement = currentElement.offsetParent;
		}

		/*D.M. 12/12/2006 BR16640
		Changed the following conditional statement to only check for IE rather than check for several
		versions of IE as well as whether HideDropDowns is true.
		
		if(this.HideDropDowns)
		
		The condition was put in place to make sure that we weren't hiding dropdowns when we didn't need
		to, like when the browser was IE7 since MS resovled the problem.  However, other elements will still
		show through submenu's when the browser is IE (in this case embedded flash on the page).
		*/

		if (ig_csom.IsIE && !ig_csom.IsMac)
		{
			if (this.transPanel == null)
			{
				this.transPanel = ig_csom.createTransparentPanel();
				/*
				igmenu_panelArray[iframeCount] = this.transPanel;
				iframeCount++;
				*/
			}
		}

		// Call 1.0 function to hide select elements
		igmenu_callDisplayMenu(true, this.id);

		if (oMenu.fireEvent(oMenu.Events.SubMenuDisplay, "(\"" + oMenu.MenuName + "\",\"" + this.id + "\", true)"))
			return;

		if (ig_csom.IsMac || (eContainer.style.filter == null))
		{

			/* D.M. BR19449, BR27749, BR20262
			Because FX insists on displaying submenu's briefly before moving them into the correct
			position in the container I had to make the submenu element visible (so that it would move
			with the container) and then shove the container offscreen, and then hide the submenu again.
			Now when the submenu is displayed it will still appear briefly, but since it's offscreen it
			will not produce an annoying and distracting flicker.  Firefox sucks.
			*/
			if (ig_csom.IsFireFox || ig_csom.IsOpera || ig_csom.IsSafari)
			{

				var oldTop = eContainer.style.top;
				var oldLeft = eContainer.style.left;
				/* D.M. BR27749 12/7/2007 - Added to prevent the width from being set to ""*/
				var oldWidth, borderRight, borderLeft;
				var borderRight;

				eContainer.style.left = "-1000px";
				eSubMenu.style.display = "";
				eSubMenu.style.visibility = 'visible';

				if (eContainer.style.width != "")
					oldWidth = eContainer.style.width
				else
					oldWidth = eContainer.offsetWidth + "px";

				/* A.T. 02/09/2008
				* commenting out the two lines below, not sure why these were set ... 
				* BR33365: Sub menu items not rendering properly when page is refreshed in firefox.
				*/
				if (oMenu.isPopup())
				{
					eContainer.style.top = oldTop;
					eContainer.style.left = oldLeft;
				}


				//if(oldWidth != "0px")
				//eContainer.style.width = "100%";//oldWidth + "px";


				eContainer.style.display = "";
				eContainer.style.visibility = 'visible';
			}
		}
		else
			if (effects.Type != 'NotSet' && effects.Type != 'Slide')
		{
			eContainer.style.filter = "progid:DXImageTransform.Microsoft." + effects.Type +
									"(duration=" + (effects.Duration / 1000) + ");"
			if (effects.ShadowWidth > 0)
				eContainer.style.filter += " progid:DXImageTransform.Microsoft.Shadow(Direction=135, Strength=" +
									effects.ShadowWidth + ",color=" + effects.ShadowColor + ");"
			if (effects.Opacity < 100)
				eContainer.style.filter += " progid:DXImageTransform.Microsoft.Alpha(Opacity=" + effects.Opacity + ");"
			try
			{
				if (eContainer.filters[0] != null)
					eContainer.filters[0].apply();
			} catch (ex) { }
			eContainer.style.display = "";
			eContainer.style.visibility = 'visible'

			try
			{
				if (eContainer.filters[0] != null)
					eContainer.filters[0].play();
			} catch (ex) { }
			/* SJZ 10/8/07 BR27166 - Any element that has a filter on, will ignore ClearType. Which causes
			* the submenu to look like it doesn't have the same styles as the root menu. The fix is simple, 
			* after we've applied the filter, we remove. Note: we only want to do this when there isn't a ShaddowWidth or Opacity set.
			* The reason being, that the user will expect to see these properties take effect */
			if (effects.ShadowWidth <= 0 && effects.Opacity >= 100)
				window.setTimeout(igmenu_createCallback(this.___filterDone, this, eContainer), effects.Duration);
		}
		else
		{
			eContainer.runtimeStyle.filter = "";
			try
			{
				if (effects.ShadowWidth > 0)
					eContainer.runtimeStyle.filter = "progid:DXImageTransform.Microsoft.Shadow(Direction=135, Strength=" +
									effects.ShadowWidth + ",color=" + effects.ShadowColor + ");"
				if (effects.Opacity < 100)/*D.M. 4/12/2007 BR21996*/
					eContainer.runtimeStyle.filter += " progid:DXImageTransform.Microsoft.Alpha(Opacity=" + effects.Opacity + ");"
			} catch (ex) { }
			eContainer.style.visibility = 'visible';
			eContainer.style.display = "";
			/* SJZ 10/8/07 BR27166 - Any element that has a filter on, will ignore ClearType. Which causes
			* the submenu to look like it doesn't have the same styles as the root menu. The fix is simple, 
			* after we've applied the filter, we remove. Note: we only want to do this when there isn't a ShaddowWidth or Opacity set.
			* The reason being, that the user will expect to see these properties take effect */
			if (effects.ShadowWidth <= 0 && effects.Opacity >= 100)
				eContainer.runtimeStyle.removeAttribute("filter");
		}

		// set submenu position	


		/* D.M. BR24642 8/22/2007 - Added for firefox, to ensure that the menu width is not incorrectly set to zero */
		var currentElement = eContainer;
		while (currentElement.scrollWidth == 0 && currentElement.parentNode != null)
			currentElement = currentElement.parentNode;

		var pageWidth = document.body.clientWidth;
		/* D.M. BR24642, BR29021 8/22/2007 - Something to watch out for here, I'm using the scrollWidth rather than clientWidth because IE7 returns the visible width of the element
		rather than the actual width of the element.  I can get away with using scrollWidth since menu elements cannot have scrollbars, and when there is no scrollbar present
		scrollWidth will return the distance between the left and right edges of the visible content.*/
		var menuWidth = (oMenu.isPopup() || ig_csom.IsFireFox) ? currentElement.scrollWidth : currentElement.offsetWidth;
		var pageHeight = document.body.clientHeight;
		if (document.documentElement)
		{
		    if(ig_csom.IsIE6 || ig_csom.IsIE55 || ig_csom.IsIE50 || ig_csom.IsIE5)
		    {
		        /* AS 02/02/2009 Bug#13182
		         * IE6 returs the full width of the BODY when we call "document.bodyclientWidth",
		         * That's why we are misscalculating the actual visible WIDTH of the document. So
		         * When we are in IE version prior 7.0, let's have the MIN, instead of MAX.
		         */
			    if (document.documentElement.clientHeight != 0)
				    pageHeight = Math.min(pageHeight, document.documentElement.clientHeight);
			    if (document.documentElement.clientWidth != 0)
				    pageWidth = Math.min(pageWidth, document.documentElement.clientWidth);		    
			}
			else
			{   
			    if (document.documentElement.clientHeight != 0)
				    pageHeight = Math.max(pageHeight, document.documentElement.clientHeight);
			    if (document.documentElement.clientWidth != 0)
				    pageWidth = Math.max(pageWidth, document.documentElement.clientWidth);			    
			}
		}

		if (ig_csom.IsSafari && window.innerHeight)
			pageHeight = window.innerHeight;

		var menuHeight = eContainer.offsetHeight;
        /* Bug#12122 4/8/2009 AStaykov taking this entire block of code from AIKIDO controls */
        var scrollTop = document.body.scrollTop + document.body.parentNode.scrollTop;
		var scrollLeft = document.body.scrollLeft + document.body.parentNode.scrollLeft;
        /* #18677 07/01/2009 AStaykov - make this block for all browsers, not FF Only */
            if (document.compatMode == "BackCompat")
            {
                pageHeight = document.body.clientHeight;
                scrollTop = document.body.scrollTop + document.body.parentNode.scrollTop;
                pageWidth = document.body.clientWidth;
                scrollLeft = document.body.scrollLeft + document.body.parentNode.scrollLeft;
            } 
            else
            {
                /* quircks */
                pageHeight = window.innerHeight;
                scrollTop = window.pageYOffset;
                pageWidth = window.innerWidth;
                scrollLeft = window.pageXOffset;
                if (ig_csom.IsIE)
                {
                    pageHeight = document.documentElement.clientHeight;
                    scrollTop = document.documentElement.scrollTop;
                    pageWidth = document.documentElement.clientWidth;
                    scrollLeft = document.documentElement.scrollLeft;
                }
            }
		var menuX = 0;
		var menuY = 0;

		var useAnimation = (effects.Type == 'Slide') ? true : false;

		if (oParent == null)
		{ // popup menu
			menuX = eContainer.offsetLeft;
			menuY = eContainer.offsetTop;
			this._popup = true;

			if (oMenu._isSection508Compliant)
				oMenu.getItems()[0].hover();
		}
		else
			if (vertical)
		{ // display next to vertical menu
			var eSubParent = this._ownerItem.getOwnerSubMenu().element;
			/*D.M. BR31816, BR32623 7/2/2008 - Changed the method used to calculate vertical position of
			menu's to account for scrolling.*/
			menuY = igmenu_getTopPos(eParent) - offsetScrollY;

			if (ig_csom.IsSafari)
			{
				/* D.M. BR23107 6/6/07 - Safari, like FX, sees whitespace as nodes in the DOM, so we have to
				get the first non-text child node to set the top offset.*/
				var firstChild = eParent.childNodes[0];
				while (firstChild.nodeType == 3)
				{
					firstChild = firstChild.nextSibling;
				}
				menuY += firstChild.offsetTop;
			}
			if (this.oParentSubMenu.scroller != null && this.oParentSubMenu.scroller.active)
			{
				menuY = menuY - this.oParentSubMenu.scroller.scrollDiv.scrollTop;
			}

			//D.M. BR32623
			if (scrollTop <= offsetScrollY)
				menuY += scrollTop;

			if (oMenu.CurrentLeftHandDisplay == false)
			{
				menuX = igmenu_getLeftPos(eSubParent) + eSubParent.offsetWidth - offsetScrollX;

				if (eParent.offsetWidth == 0 && ig_csom.IsSafari)
				{
					var temp = eParent.offsetParent;
					var width = 0;
					while (temp != null && width == 0)
					{
						width += temp.offsetWidth;
						temp = temp.offsetParent;
					}
					menuX += width;
				}

			}
			else
				menuX = igmenu_getLeftPos(eParent) - menuWidth;

			//D.M. BR32623
			if (scrollLeft <= offsetScrollX)
				menuX += scrollLeft;

			var switched = oMenu.CurrentLeftHandDisplay != oMenu.LeftHandDisplay;
			// Check which way to align the menu
			if (oMenu.CurrentLeftHandDisplay == false && !switched)
			{ // align right
				if ((menuX + menuWidth) > pageWidth + scrollLeft)
				{
					oMenu.CurrentLeftHandDisplay = true; // change to left
					/* menuX = igmenu_getLeftPos(eParent) - eParent.offsetWidth; */
					/* AS 2009-05-28 Bug#17132, just substract from the calculated X menuWidth and parent's width  */
					menuX = menuX - eParent.offsetWidth - menuWidth;
					// AS 20081002 #8559
					if (menuX < 0) menuX = 0;
				}
			}
			else
				if (oMenu.CurrentLeftHandDisplay == true && !switched)
			{ // aligned left
				if ((menuX < 0))
				{
					oMenu.CurrentLeftHandDisplay = false; // change to right
					menuX = igmenu_getLeftPos(eParent) + eParent.offsetWidth;
				}
			}
		}
		else
		{ // display under horizontal menu
			var eSubParent = this._ownerItem.getOwnerSubMenu().element;
			/* D.M. BR24939, BR32623 7/1/2008 - In most cases we want to subtract the offsetScroll position from the
			* calculated top, or left position.  If the offsetScroll is equal to the scroll top and left of the page
			* we do not need to subtract the offsetScroll position so we add it back.
			*/
			menuX = igmenu_getLeftPos(eParent) - offsetScrollX;
			menuY = igmenu_getTopPos(eSubParent) + eSubParent.offsetHeight - offsetScrollY;

			if (scrollTop <= offsetScrollY)
				menuY += scrollTop;
			if (scrollLeft <= offsetScrollX)
				menuX += scrollLeft;
		}

		if (ig_csom.IsIE && !ig_csom.IsMac)
		{
			var scrollHeight;
			if (!this.scroller)
				scrollHeight = eSubMenu.firstChild.firstChild.scrollHeight;
			else
				scrollHeight = this.scroller.table.scrollHeight;
			if (scrollHeight > pageHeight - 4)
			{
				if (!this.scroller)
				{
					this.scroller = new igmenu_scroller(eSubMenu);
				}
				this.scroller.show();

				useAnimation = false;
				var divsHeight = this.scroller.topDiv.offsetHeight + this.scroller.bottomDiv.offsetHeight + 8;
				this.scroller.setScrollHeight(pageHeight - divsHeight);
				menuHeight = eContainer.offsetHeight;
			}
			else
			{
				if (this.scroller)
				{
					/*rmk: 11.12.2008 - 5991 bugfix*/
					this.scroller.setScrollHeight(scrollHeight);
					this.scroller.hide();
					this.scroller = null;
				}
			}
		}

		if (menuX + menuWidth > pageWidth + scrollLeft)
			menuX = pageWidth - menuWidth + scrollLeft - 8;
		if(menuX < scrollLeft)
		menuX += scrollLeft;
		/* Bug#12122 4/8/2009 AStaykov FireFox issues */
		if ((menuY + menuHeight) > (pageHeight + scrollTop))
		{
            if((pageHeight - 8) > menuHeight)
		        menuY = pageHeight - menuHeight + scrollTop - 8;
		    else
		        menuY = scrollTop;
		}
		if ((oParent && oParent.isTopLevelItem()) || !oMenu._currentScrollTop || (oMenu._currentScrollTop && oMenu._currentScrollTop != scrollTop && scrollTop > 0))
		{
			if (menuY < scrollTop && oMenu.isPopup())
			{
				menuY += scrollTop;
				oMenu._currentScrollTop = scrollTop;

			} else if (!oMenu.isPopup() && menuY < scrollTop)/* D.M. TFS10359 12/12/2008 - This if should also check if the scrollTop is greater than menuY. */
			{
				menuY += scrollTop;
				oMenu._currentScrollTop = scrollTop;
			}
		}


		eContainer.style.top = menuY.toString() + "px";
		eContainer.style.left = menuX.toString() + "px";

		/* D.M. TFS6441 12/2/2008 -  Set position relative on the table element that list menu items, these fixes shouldn't be required anymore. */
		//		if (!ig_csom.IsFireFox && currentElement.style.width == "")
		//			eContainer.style.width = menuWidth.toString() + "px";
		//      * D.M. BR29021, BR30291 1/22/2008 - attempting to compensate for the width of the menu borders in firefox.*/
		//		if (oMenu.isPopup() && ig_csom.IsFireFox)
		//			eContainer.style.width = (menuWidth + (currentElement.childNodes[1].offsetWidth - currentElement.childNodes[1].clientWidth)) + "px";

		this.eContainer = eContainer;

		if (this.transPanel != null)
		{
			this.transPanel.setPosition(eContainer.offsetTop, eContainer.offsetLeft, eContainer.offsetWidth, eContainer.offsetHeight);
			this.transPanel.show();
		}

		if (useAnimation)
		{
			this.animate = new ig_SlideRevealAnimation();
			this.animate.setElement(eSubMenu);
			this.animate.setContainer(eSubMenu.parentNode);
			this.animate.setRate(AnimationRateEnum.Decelerate);
			this.animate.finishPos = 0;
			if (vertical)
			{
				this._vertical = true;
				this.animate.setDirection(AnimationDirectionEnum.Right);
				eSubMenu.style.visibility = "";
				eSubMenu.style.display = "";
				this.animate.startPos = -eSubMenu.scrollWidth;
			}
			else
			{
				this.animate.setDirection(AnimationDirectionEnum.Down);
				this.animate.startPos = -eSubMenu.scrollHeight;
			}
			this.animate.play();
		}
		else
		{
			eSubMenu.style.display = "";
			eSubMenu.style.visibility = "visible";
		}

		/* D.M. 11/11/2008 - Bug 9406  */
		var callback = igmenu_createCallback(this._checkPosition, this);
		igmenu_displaySubMenuTimerId = setInterval(callback, 100);
	}


	//private
	ig_SubMenu.prototype._checkPosition = function()
	{
		var ScrollTop = oMenu.getScrollTop();
		var ScrollLeft = oMenu.getScrollLeft();


		if ((oMenu._lastScrollX != ScrollLeft || oMenu._lastScrollY != ScrollTop) && this._visible)
			if (ig_oActiveMenu)
			ig_oActiveMenu.hideSubMenus();

		oMenu._lastScrollX = ScrollLeft;
		oMenu._lastScrollY = ScrollTop;

	}

	/* SJZ 10/8/07 BR27166 - Any element that has a filter on, will ignore ClearType. Which causes
	* the submenu to look like it doesn't have the same styles as the root menu. The fix is simple, 
	* after we've applied the filter, we remove. When the user has a Filter animation set, we need
	* to remove the filter, after the animation occurs, so we set a timer for the same duration as the 
	* animation*/
	ig_SubMenu.prototype.___filterDone = function(container)
	{
		container.style.removeAttribute("filter");
	}

	/*BR23107*/
	ig_isSubmenuCreated = true;
	return new ig_SubMenu(oMenu, eSub);
}

function ig_SubMenu(oMenu, eSub)
{
	this.init(eSub);
	this.WebMenu = oMenu;
	this._currentDisplayedSubMenu = null;
	this._hoveredItem = null;
	this._selectedItem = null;
	this._ownerItem = null;
	this._visible = false;
}

function ig_WebUIElement(element)
{
	if (arguments.length > 0)
	{
		this.init(id, element);
	}
}

ig_WebUIElement.prototype.init = function(element)
{
	this.id = element.id;
	this.element = element;
	ig_all[this.id] = this;
}

ig_WebUIElement.prototype.constructor = ig_WebUIElement;
ig_WebUIElement.prototype.getElement = function()
{
	return this.element;
}

hideAnimationComplete = function(element, params)
{
	params.tr.style.visibility = "hidden";
	params.tr.style.display = "none";
}

igmenu_createCallback = function(method, context, param1, param2, param3)
{

	return function()
	{
		method.apply(context, [param1, param2, param3]);
	}
}

