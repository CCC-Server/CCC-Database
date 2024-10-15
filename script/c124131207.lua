--아십이수 이글소드
local s,id=GetID()
function s.initial_effect(c)
	--xyz summon
	Xyz.AddProcedure(c,nil,4,3,s.ovfilter,aux.Stringid(id,0),3,s.xyzop)
	c:EnableReviveLimit()
	--atk
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EFFECT_UPDATE_DEFENSE)
	e2:SetValue(s.defval)
	c:RegisterEffect(e2)
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_DAMAGE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(s.ctcon)
	e3:SetOperation(s.ctop)
	c:RegisterEffect(e3)
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_DESTROYED)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCountLimit(1,id)
	e4:SetCondition(s.spcon)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end
function s.ovfilter(c,tp,lc)
	return c:IsFaceup() and c:IsSetCard(0xf1,lc,SUMMON_TYPE_XYZ,tp) and not c:IsSummonCode(lc,SUMMON_TYPE_XYZ,tp,id)
end
function s.xyzop(e,tp,chk)
	if chk==0 then return Duel.GetFlagEffect(tp,id)==0 end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1)
	return true
end
function s.atkfilter(c)
	return c:IsSetCard(0xf1) and c:GetAttack()>=0
end
function s.atkval(e,c)
	local g=e:GetHandler():GetOverlayGroup():Filter(s.atkfilter,nil)
	return g:GetSum(Card.GetAttack)
end
function s.deffilter(c)
	return c:IsSetCard(0xf1) and c:GetDefense()>=0
end
function s.defval(e,c)
	local g=e:GetHandler():GetOverlayGroup():Filter(s.deffilter,nil)
	return g:GetSum(Card.GetDefense)
end
function s.ctfilter(c,tp)
	return  c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsPreviousControler(tp) and c:IsReason(REASON_BATTLE+REASON_EFFECT)
end
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.ctfilter,1,nil,tp)
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,id)
	Duel.Damage(1-tp,400,REASON_EFFECT)
end
function s.spconfilter(c,tp)
	return c:IsPreviousControler(tp) and c:IsPreviousSetCard(0xf1) and c:IsReason(REASON_BATTLE+REASON_EFFECT)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return eg and not eg:IsContains(c) and eg:IsExists(s.spconfilter,1,c,tp)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) and Duel.IsExistingMatchingCard(s.gfilter,tp,LOCATION_GRAVE,0,1,nil,c,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.gfilter(c,xc,tp)
	return c:IsSetCard(0xf1) and c:IsMonster() and c:IsCanBeXyzMaterial(xc,tp,REASON_EFFECT)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		local g=Duel.SelectMatchingCard(tp,s.gfilter,tp,LOCATION_GRAVE,0,1,1,nil,c,tp)
		if #g==0 then return end
		Duel.HintSelection(g,true)
		Duel.BreakEffect()
		Duel.Overlay(c,g)
	end
end