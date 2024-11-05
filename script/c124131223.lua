--Lord of HERO
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Fusion Summon procedure ("Blue-Eyes Ultimate Dragon")
	local f0=Fusion.AddProcMix(c,true,true,76263644,s.ffilter)[1]
	f0:SetDescription(aux.Stringid(id,0))
	--Fusion Summon procedure (3 "Blue-Eyes" monsters)
	local f1=Fusion.AddProcMixN(c,true,true,s.ffilter2,1,s.ffilter,1)[1]
	f1:SetDescription(aux.Stringid(id,1))
	--Must be Fusion Summoned
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetValue(aux.fuslimit)
	c:RegisterEffect(e1)
	--상대 필드의 몬스터가 효과를 발동했을 때에 발동할 수 있다. 상대 필드의 모든 앞면 표시 몬스터의 효과를 무효로 하고, 그 카드를 전부 파괴한다.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DISABLE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.selfspcon)
	e2:SetTarget(s.selfsptg)
	e2:SetOperation(s.selfspop)
	c:RegisterEffect(e2)
	--필드의 이 카드가 파괴되어 묘지로 보내졌을 경우에 발동할 수 있다. "드라군 D-엔드" 1장이나 "Lord of HERO" 이외의 "히어로" 융합 몬스터 1장을 소환 조건을 무시하고 자신의 묘지 / 제외 상태에서 특수 소환한다.
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCondition(s.shcon)
	e3:SetTarget(s.shtg)
	e3:SetOperation(s.shop)
	c:RegisterEffect(e3)
end
function s.ffilter(c,fc,sumtype,tp)
	return c:IsSetCard(0x3008) and c:IsType(TYPE_FUSION)
end
function s.ffilter2(c,fc,sumtype,tp)
	return c:IsSetCard(0xc008) and c:IsType(TYPE_FUSION)
end
function s.selfspcon(e,tp,eg,ep,ev,re,r,rp)
	local loc,controller=Duel.GetChainInfo(ev,CHAININFO_TRIGGERING_LOCATION,CHAININFO_TRIGGERING_CONTROLER)
	return controller==1-tp and loc==LOCATION_MZONE and Duel.IsChainDisablable(ev)
end
function s.selfsptg(e,tp,eg,ep,ev,re,r,rp,chk)
    if chk==0 then return true end
    Duel.SetOperationInfo(0,CATEGORY_DISABLE,nil,1,0,LOCATION_MZONE)
end
function s.selfspop(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(aux.FaceupFilter(Card.IsType,TYPE_EFFECT),tp,0,LOCATION_MZONE,nil)
    for tc in aux.Next(g) do
        Duel.NegateRelatedChain(tc,RESET_TURN_SET)
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_SINGLE)
        e1:SetCode(EFFECT_DISABLE)
        e1:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e1)
        local e2=Effect.CreateEffect(e:GetHandler())
        e2:SetType(EFFECT_TYPE_SINGLE)
        e2:SetCode(EFFECT_DISABLE_EFFECT)
        e2:SetValue(RESET_TURN_SET)
        e2:SetReset(RESET_EVENT+RESETS_STANDARD)
        tc:RegisterEffect(e2)
    end
	Duel.BreakEffect()
	local dg=Duel.GetFieldGroup(tp,0,LOCATION_ONFIELD)
	Duel.Destroy(dg,REASON_EFFECT)
end
function s.shcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsPreviousLocation(LOCATION_ONFIELD) and e:GetHandler():IsReason(REASON_DESTROY)
end
function s.spfilter(c)
	return (c:IsCode(76263644) or ((c:IsSetCard(0x8) and c:IsType(TYPE_FUSION)))) and not c:IsCode(124131223)
end
function s.shtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end
function s.shop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<1 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,true,false,POS_FACEUP)
	end
end
