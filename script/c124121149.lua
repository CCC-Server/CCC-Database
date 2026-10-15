--붉은 눈 융합 for AI
--※ cdb의 alias 칸에 6172122("붉은 눈 융합")를 입력해서
--   "이 카드명은 룰상 「붉은 눈 융합」으로 취급한다"를 처리한다.
local s,id=GetID()
local CARD_REDEYES_FUSION=6172122
local CARD_REDEYES_WYVERN=67300516 --붉은 눈의 비룡
function s.initial_effect(c)
	--①: 패 / 덱의 몬스터를 소재로 "붉은 눈" 융합 몬스터를 융합 소환
	local e1=Fusion.CreateSummonEff({handler=c,fusfilter=aux.FilterBoolFunction(Card.ListsArchetypeAsMaterial,SET_RED_EYES),
									 matfilter=s.matfilter,extrafil=s.fextra,stage2=s.stage2,extratg=s.extratg})
	--"붉은 눈 융합"과 카운트 공유 (이 카드명의 카드는 1턴에 1장)
	e1:SetCountLimit(1,CARD_REDEYES_FUSION,EFFECT_COUNT_CODE_OATH)
	c:RegisterEffect(e1)
	--②: 자신 엔드 페이즈에 묘지의 이 카드를 제외하고, 덱에서 "붉은 눈의 비룡"을 묘지로
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_PHASE+PHASE_END)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCondition(s.tgcon)
	e2:SetCost(Cost.SelfBanish)
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)
end
s.listed_series={SET_RED_EYES}
s.listed_names={CARD_REDEYES_B_DRAGON,CARD_REDEYES_WYVERN}

--① 소재는 패 / 덱만 (필드 제외)
function s.matfilter(c)
	return c:IsLocation(LOCATION_HAND|LOCATION_DECK)
end
function s.fextra(e,tp,mg,sumtype)
	return Duel.GetMatchingGroup(Fusion.IsMonsterFilter(Card.IsAbleToGrave),tp,LOCATION_DECK,0,nil),s.fcheck
end
function s.fcheck(tp,sg,fc,sumtype,tp)
	return sg:IsExists(s.ffilter,1,nil,fc,sumtype,tp)
end
function s.ffilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_RED_EYES,fc,sumtype,tp) and (not fc.material or c:IsSummonCode(fc,sumtype,tp,fc.material))
end
function s.extratg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,0,tp,LOCATION_DECK)
	--이 카드의 발동에 대해 자신은 다른 효과를 발동할 수 없다
	if e:IsHasType(EFFECT_TYPE_ACTIVATE) then
		Duel.SetChainLimit(s.chlimit)
	end
end
function s.chlimit(e,rp,tp)
	return rp~=tp
end
--특수 소환한 몬스터의 카드명은 "붉은 눈의 흑룡"으로 취급
function s.stage2(e,tc,tp,mg,chk)
	if chk==1 then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_CODE)
		e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e1:SetValue(CARD_REDEYES_B_DRAGON)
		e1:SetReset(RESET_EVENT|RESETS_STANDARD)
		tc:RegisterEffect(e1)
	end
end

--② 자신의 엔드 페이즈
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsTurnPlayer(tp)
end
function s.tgfilter(c)
	return c:IsCode(CARD_REDEYES_WYVERN) and c:IsAbleToGrave()
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end
