-- 데드웨어 트로이 웨어
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 패의 이 카드를 상대에게 보여주고 발동. 덱에서 "데드웨어" 몬스터 1장을 상대의 패에 넣는다. 그 후, 이 카드를 패에서 특수 소환한다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.spcost)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ②: 몬스터 카드명을 1개 선언하여 발동. 상대는 자신의 패에 선언한 카드명의 몬스터가 있을 경우, 그 몬스터를 특수 소환한다.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.declareidtg)
	e2:SetOperation(s.declareidop)
	c:RegisterEffect(e2)

	-- ③: 자신 / 상대 턴에 상대 필드의 몬스터 1장을 대상으로 하고 발동. 그 몬스터와 이 카드만을 소재로 '데드웨어' 싱크로 소환을 실행한다. (수정됨)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.syntg)
	e3:SetOperation(s.synop)
	c:RegisterEffect(e3)
end

-- ① 효과 로직
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return not e:GetHandler():IsPublic() end
	Duel.ConfirmCards(1-tp,e:GetHandler())
end
function s.thfilter(c)
	return c:IsSetCard(0xc55) and c:IsMonster() and c:IsAbleToHand()
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		if Duel.SendtoHand(g,1-tp,REASON_EFFECT)>0 then
			Duel.ConfirmCards(tp,g)
			Duel.ShuffleHand(1-tp)
			local c=e:GetHandler()
			if c:IsRelateToEffect(e) then
				Duel.BreakEffect()
				Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
			end
		end
	end
end

-- ② 효과 로직
function s.declareidtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CODE)
	local ac=Duel.AnnounceCard(tp)
	Duel.SetTargetParam(ac)
	e:SetLabel(ac)
end
function s.declareidop(e,tp,eg,ep,ev,re,r,rp)
	local ac=e:GetLabel()
	local g=Duel.GetMatchingGroup(Card.IsCode,tp,0,LOCATION_HAND,nil,ac)
	if #g>0 and Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0 then
		Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_SPSUMMON)
		local sg=g:Select(1-tp,1,1,nil)
		Duel.SpecialSummon(sg,0,1-tp,1-tp,false,false,POS_FACEUP)
	end
end

-- ③ 효과 로직 (싱크로 몬스터 직접 선택 가능하게 수정)
function s.scfilter(c,mg)
	-- mg(이 카드+상대 몬스터)를 소재로 소환 가능한 데드웨어 싱크로 필터
	return c:IsSetCard(0xc55) and c:IsSynchroSummonable(nil,mg)
end
function s.matfilter(tc,c,tp)
	if not tc:IsFaceup() or not tc:IsCanBeSynchroMaterial() then return false end
	-- 가상으로 소재 권한을 부여하여 엑스트라 덱에 소환 가능한 몬스터가 있는지 체크
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_SYNCHRO_MATERIAL)
	tc:RegisterEffect(e1,true)
	local mg=Group.FromCards(c,tc)
	local res=Duel.IsExistingMatchingCard(s.scfilter,tp,LOCATION_EXTRA,0,1,nil,mg)
	e1:Reset()
	return res
end
function s.syntg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and s.matfilter(chkc,e:GetHandler(),tp) end
	if chk==0 then return Duel.IsExistingTarget(s.matfilter,tp,0,LOCATION_MZONE,1,nil,e:GetHandler(),tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.matfilter,tp,0,LOCATION_MZONE,1,1,nil,e:GetHandler(),tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.synop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and c:IsFaceup() and tc and tc:IsFaceup() and tc:IsRelateToEffect(e) then
		-- 상대 몬스터에게 일시적으로 싱크로 소재 권한 부여
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SYNCHRO_MATERIAL)
		tc:RegisterEffect(e1,true)
		local mg=Group.FromCards(c,tc)
		
		-- 플레이어가 직접 엑스트라 덱에서 고르도록 변경
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.scfilter,tp,LOCATION_EXTRA,0,1,1,nil,mg)
		local sc=g:GetFirst()
		
		if sc then
			-- 소환 성공 / 무효 시 부여했던 소재 권한(e1)을 제거하도록 이벤트 등록
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
			e2:SetCode(EVENT_SPSUMMON_SUCCESS)
			e2:SetReset(RESET_EVENT|(RESETS_STANDARD&~RESET_TOFIELD))
			e2:SetOperation(function(e) e:GetLabelObject():Reset() e:Reset() end)
			e2:SetLabelObject(e1)
			sc:RegisterEffect(e2,true)
			local e3=e2:Clone()
			e3:SetCode(EVENT_SPSUMMON_NEGATED)
			sc:RegisterEffect(e3,true)
			
			-- 선택한 몬스터로 싱크로 소환 실행
			Duel.SynchroSummon(tp,sc,nil,mg)
		else
			-- 선택을 취소했을 경우 효과 리셋
			e1:Reset()
		end
	end
end