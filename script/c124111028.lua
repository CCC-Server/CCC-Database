--생명의 나선
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Fusion.CreateSummonEff(c,aux.FilterBoolFunction(Card.IsSetCard,0xfd1),nil,s.fextra,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,s.extratg)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_CHANGE_CODE)
	e2:SetRange(LOCATION_REMOVED+LOCATION_GRAVE+LOCATION_DECK)
	e2:SetValue(id-1)
	c:RegisterEffect(e2)
end
function s.fxfilter(c)
	return c:IsPublic() and c:IsSetCard(0xfd1) and c:IsMonster()
end
function s.fcheck(tp,sg,fc)
	return sg:FilterCount(Card.IsLocation,nil,LOCATION_EXTRA)<=2
end
function s.fextra(e,tp,mg)
	if Duel.IsExistingMatchingCard(s.fxfilter,tp,LOCATION_HAND,0,3,nil) then
		local sg=Duel.GetMatchingGroup(s.exfilter,tp,LOCATION_EXTRA,0,nil)
		if #sg>0 then
			return sg,s.fcheck
		end
	end
	return nil
end
function s.exfilter(c)
	return c:IsSetCard(0xfd1) and c:IsAbleToGrave()
end
function s.extratg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,0,tp,LOCATION_EXTRA)
end