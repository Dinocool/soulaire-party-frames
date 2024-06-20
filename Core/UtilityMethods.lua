--Returns if we should even bother running update code
--If the frame isn't visible or the unit this frame is updating on doesn't exist, don't bother
function SOUL_ShouldUpdate(self)
    return ( self:IsShown() and  UnitGUID(self.unit) )
end
