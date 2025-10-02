--양까치 버스터 콜
local s,id=GetID()
function c128220068.initial_effect(c)
	local e1=Ritual.AddProcEqual{handler=c,filter=s.ritualfil,extrafil=s.extrafil,extratg=s.extratg}
	c:RegisterEffect(e1)
	--Return itself to the hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.condition)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end
function s.ritualfil(c)
	return c:IsSetCard(0xc23)
end
function s.exfilter0(c)
	return c:IsSetCard(0xc23) and c:IsLevelAbove(1) and c:IsAbleToGrave()
end
function s.extraop(mg,e,tp,eg,ep,ev,re,r,rp)
	local mat2=mg:Filter(Card.IsLocation,nil,LOCATION_EXTRA)
	mg:Sub(mat2)
	Duel.ReleaseRitualMaterial(mg)
	Duel.SendtoGrave(mat2,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
end
function s.forcedgroup(c,e,tp)
	return (c:IsLocation(LOCATION_HAND|LOCATION_ONFIELD)) or (c:IsSetCard(0xc23) and c:IsLocation(LOCATION_EXTRA))
end
function s.mfilter(c)
	return not Duel.IsPlayerAffectedByEffect(c:GetControler(),CARD_SPIRIT_ELIMINATION) and c:HasLevel() and c:IsSetCard(0xc23)
		and c:IsMonster() and c:IsAbleToRemove()
end
function s.extrafil(e,tp,eg,ep,ev,re,r,rp,chk)
	return Duel.GetMatchingGroup(s.mfilter,tp,LOCATION_EXTRA,0,nil)
end
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsType,TYPE_SPIRIT),tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsType,TYPE_FLIP),tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(aux.FaceupFilter(Card.IsType,TYPE_TUNER),tp,LOCATION_MZONE,0,1,nil)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToHand() end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	if e:GetHandler():IsRelateToEffect(e) then
		Duel.SendtoHand(e:GetHandler(),nil,REASON_EFFECT)
	end
end