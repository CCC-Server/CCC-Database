--헤블론-빛의 우상 호루스
local s,id=GetID()
function s.initial_effect(c)
	--엑시즈 소환 절차: 빛 속성 레벨 8 몬스터 × 2
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_LIGHT),8,2)
	c:EnableReviveLimit()

	--① 수비력 상승: 소재 수 × 500
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_DEFENSE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.defval)
	c:RegisterEffect(e1)

	--② 자신 필드의 다른 빛 속성 엑시즈 몬스터에게 소재 이전
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.mattg)
	e2:SetOperation(s.matop)
	c:RegisterEffect(e2)
end

--① DEF 상승
function s.defval(e,c)
	return c:GetOverlayCount()*500
end

--② 대상: 자신 필드의 다른 빛 속성 엑시즈 몬스터
function s.matfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsAttribute(ATTRIBUTE_LIGHT)
end
function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and s.matfilter(chkc) and chkc~=e:GetHandler() end
	if chk==0 then return Duel.IsExistingTarget(s.matfilter,tp,LOCATION_MZONE,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.matfilter,tp,LOCATION_MZONE,0,1,1,e:GetHandler())
end
function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not c:IsRelateToEffect(e) or c:IsImmuneToEffect(e) then return end
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local g=c:GetOverlayGroup()
		if #g>0 then
			Duel.Overlay(tc,g)
		end
		Duel.Overlay(tc,Group.FromCards(c))
	end
end